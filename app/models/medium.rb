class Medium < ApplicationRecord
  belongs_to :user
  belongs_to :event

  has_one_attached :photo, dependent: :detach do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [ 400, 400 ]
  end

  before_destroy :cache_blob
  after_destroy  :purge_cached_blob

  def cache_blob
    @cached_blob = photo.blob if photo.attached?
  end

  def purge_cached_blob
    @cached_blob&.purge rescue Aws::S3::Errors::NoSuchKey
  end

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  URL_EXPIRY = 518400

  validate :photo_content_type

  def presigned_url(expires_in: URL_EXPIRY)
    return nil unless photo.attached?
    url = photo.url(expires_in: expires_in)
    rewrite_localstack_url(url)
  end

  def thumbnail_url(expires_in: URL_EXPIRY)
    return nil unless photo.attached?
    url = with_variant_lock { photo.variant(:thumbnail).processed }.url(expires_in: expires_in)
    rewrite_localstack_url(url)
  end

  private

  # Session-scoped (not transaction-scoped) on purpose: ActiveStorage's own
  # variant-creation path relies on a top-level transaction to fire its
  # after_commit upload callback while the transformed image's tempfile is
  # still open. Wrapping that in an outer transaction here would defer the
  # callback until *this* transaction commits, by which point the tempfile
  # has already been cleaned up, breaking the upload. A session-level lock
  # avoids opening any extra transaction around it.
  def with_variant_lock
    connection = ActiveRecord::Base.connection
    lock_key = ActiveRecord::Base.sanitize_sql(["SELECT pg_advisory_lock(?)", photo.blob_id])
    unlock_key = ActiveRecord::Base.sanitize_sql(["SELECT pg_advisory_unlock(?)", photo.blob_id])

    connection.execute(lock_key)
    yield
  ensure
    connection.execute(unlock_key) if connection
  end

  def photo_content_type
    return unless photo.attached?
    unless ALLOWED_CONTENT_TYPES.include?(photo.content_type)
      errors.add(:photo, "must be a JPEG, PNG, or WebP")
    end
  end

  def rewrite_localstack_url(url)
    return url unless Rails.env.development? && url.to_s.include?("localstack")
    url.sub("http://localstack:4566", ENV.fetch("S3_PUBLIC_ENDPOINT", "http://localhost:4567"))
  end
end
