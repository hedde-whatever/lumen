class Medium < ApplicationRecord
  belongs_to :user
  belongs_to :event

  has_one_attached :photo, dependent: :purge do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [ 400, 400 ]
  end

  before_destroy :purge_photo

  def purge_photo
    photo.purge if photo.attached?
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
    url = photo.variant(:thumbnail).processed.url(expires_in: expires_in)
    rewrite_localstack_url(url)
  end

  private

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
