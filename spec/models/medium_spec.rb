require "rails_helper"

RSpec.describe Medium, type: :model do
  # ActiveStorage uploads attached files from an after_commit callback (see
  # ActiveStorage::Attached::Model#has_one_attached), which only fires on a
  # genuine top-level commit. Transactional fixtures wrap the whole example
  # in a savepoint that never truly commits, which breaks that callback, so
  # they're disabled for this file. This also lets concurrent threads see
  # each other's committed data, which the concurrency test below depends on.
  self.use_transactional_tests = false

  before { ActiveStorage::Current.url_options = { host: "localhost" } }

  let(:user)   { create(:user) }
  let(:event)  { create(:event, user: user) }
  let(:medium) { attach_photo(build(:medium, user: user, event: event)) }

  after do
    medium.photo.purge if medium.photo.attached?
    medium.destroy
    event.destroy
    user.destroy
  end

  def attach_photo(medium)
    medium.photo.attach(
      fixture_file_upload(Rails.root.join("spec/fixtures/files/photo.jpg"), "image/jpeg")
    )
    medium.save!
    medium
  end

  describe "#thumbnail_url" do
    it "returns nil when no photo is attached" do
      bare = create(:medium, user: user, event: event)
      expect(bare.thumbnail_url).to be_nil
      bare.destroy
    end

    it "creates exactly one variant record for the blob" do
      expect { medium.thumbnail_url }.to change(ActiveStorage::VariantRecord, :count).by(1)
    end

    it "reuses the existing variant record on subsequent calls" do
      medium.thumbnail_url
      expect { medium.thumbnail_url }.not_to change(ActiveStorage::VariantRecord, :count)
    end

    it "holds the advisory lock, keyed on the blob id, across the whole variant creation" do
      statements = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        statements << payload[:sql]
      end

      medium.thumbnail_url

      blob_id      = medium.photo.blob_id
      lock_index   = statements.index { |sql| sql.include?("pg_advisory_lock(#{blob_id})") }
      insert_index = statements.index { |sql| sql.include?(%(INSERT INTO "active_storage_variant_records")) }
      unlock_index = statements.index { |sql| sql.include?("pg_advisory_unlock(#{blob_id})") }

      expect(lock_index).not_to be_nil, "expected an advisory lock statement for blob #{blob_id}"
      expect(insert_index).not_to be_nil, "expected a variant record INSERT"
      expect(unlock_index).not_to be_nil, "expected an advisory unlock statement for blob #{blob_id}"
      # Proves the INSERT (and the image upload it triggers) happens between
      # the lock and unlock, not after the lock already released.
      expect(lock_index).to be < insert_index
      expect(insert_index).to be < unlock_index
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it "releases the lock even if variant processing raises" do
      allow_any_instance_of(ActiveStorage::Variation).to receive(:transform).and_raise("boom")

      expect { medium.thumbnail_url }.to raise_error("boom")

      # Session-level advisory locks are re-entrant within the same
      # connection, so re-checking from medium's own connection would pass
      # even if the lock leaked. Check from a genuinely different connection
      # instead: pg_try_advisory_lock returns false (rather than blocking) if
      # another session still holds the key.
      acquired = nil
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |other|
          acquired = other.select_value(
            ActiveRecord::Base.sanitize_sql(["SELECT pg_try_advisory_lock(?)", medium.photo.blob_id])
          )
          other.execute(
            ActiveRecord::Base.sanitize_sql(["SELECT pg_advisory_unlock(?)", medium.photo.blob_id])
          ) if acquired
        end
      end.join

      expect(acquired).to be true
    end
  end

  describe "concurrent access to the same blob's variant", :aggregate_failures do
    it "blocks a second caller until the first releases the lock for the same blob" do
      locked        = Queue.new
      release_first = Queue.new
      second_pid    = Queue.new

      first = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          medium.send(:with_variant_lock) do
            locked << true
            release_first.pop
          end
        end
      end
      locked.pop # wait until the first thread has definitely acquired the lock

      second = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          second_pid << conn.select_value("SELECT pg_backend_pid()")
          medium.send(:with_variant_lock) {}
        end
      end

      # Poll Postgres itself (not a sleep, and not Ruby-level ordering after
      # release, which isn't guaranteed between two independent threads)
      # until the second backend is genuinely parked waiting on a lock. This
      # is the actual proof of mutual exclusion.
      pid = second_pid.pop.to_i
      waiting = false
      50.times do
        waiting = ActiveRecord::Base.connection.select_value(
          "SELECT wait_event_type = 'Lock' FROM pg_stat_activity WHERE pid = #{pid}"
        )
        break if [ true, "t" ].include?(waiting)
        sleep 0.02
      end
      expect([ true, "t" ]).to include(waiting), "expected the second caller to be blocked on the advisory lock"

      release_first << true
      expect(first.join(2)).not_to be_nil, "first caller did not finish"
      expect(second.join(2)).not_to be_nil, "second caller did not finish after the lock was released"
    end

    it "never raises a duplicate-key error and only ever creates one variant record" do
      medium # eager-create outside the threads
      thread_count = 8

      barrier = Concurrent::CyclicBarrier.new(thread_count)
      errors  = Queue.new

      threads = Array.new(thread_count) do
        Thread.new do
          ActiveStorage::Current.url_options = { host: "localhost" }
          ActiveRecord::Base.connection_pool.with_connection do
            barrier.wait
            Medium.find(medium.id).thumbnail_url
          rescue => e
            errors << e
          end
        end
      end
      threads.each(&:join)

      expect(errors).to be_empty
      expect(ActiveStorage::VariantRecord.where(blob_id: medium.photo.blob_id).count).to eq(1)
    end
  end
end
