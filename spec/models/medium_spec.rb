require "rails_helper"

RSpec.describe Medium, type: :model do
  before { ActiveStorage::Current.url_options = { host: "localhost" } }

  def attach_photo(medium)
    medium.photo.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/photo.jpg")),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    medium.save!
    medium
  end

  describe "#thumbnail_url" do
    let(:user)  { create(:user) }
    let(:event) { create(:event, user: user) }
    let(:medium) { attach_photo(build(:medium, user: user, event: event)) }

    it "returns nil when no photo is attached" do
      bare = create(:medium, user: user, event: event)
      expect(bare.thumbnail_url).to be_nil
    end

    it "creates exactly one variant record for the blob" do
      expect { medium.thumbnail_url }.to change(ActiveStorage::VariantRecord, :count).by(1)
    end

    it "reuses the existing variant record on subsequent calls" do
      medium.thumbnail_url
      expect { medium.thumbnail_url }.not_to change(ActiveStorage::VariantRecord, :count)
    end

    it "wraps variant creation in a Postgres advisory lock keyed on the blob id" do
      locked_ids = []
      allow(ActiveRecord::Base.connection).to receive(:execute).and_wrap_original do |original, sql, *args|
        locked_ids << sql[/pg_advisory_xact_lock\((\d+)\)/, 1] if sql.include?("pg_advisory_xact_lock")
        original.call(sql, *args)
      end

      medium.thumbnail_url

      expect(locked_ids).to eq([ medium.photo.blob_id.to_s ])
    end
  end

  # Transactional fixtures pin every thread to the same DB connection (see
  # ActiveRecord::TestFixtures#lock_threads), which would hide the very race
  # this locking exists to prevent. Disable them here so each thread gets its
  # own Postgres backend, matching what actually happens across concurrent
  # Puma request threads in production.
  describe "concurrent access to the same blob's variant", :aggregate_failures do
    self.use_transactional_tests = false

    let(:user)   { create(:user) }
    let(:event)  { create(:event, user: user) }
    let(:medium) { attach_photo(build(:medium, user: user, event: event)) }

    after do
      medium.photo.purge
      medium.destroy
      event.destroy
      user.destroy
    end

    it "never raises a duplicate-key error and only ever creates one variant record" do
      medium # eager-create outside the threads

      barrier = Concurrent::CyclicBarrier.new(5)
      errors  = Queue.new

      threads = Array.new(5) do
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
