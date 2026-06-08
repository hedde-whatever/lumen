class Medium < ApplicationRecord
  belongs_to :user
  belongs_to :event

  has_one_attached :photo, dependent: :purge

  def presigned_url(expires_in: 518400)
    return nil unless photo.attached?
    url = photo.url(expires_in: expires_in)
    rewrite_localstack_url(url)
  end

  private

  def rewrite_localstack_url(url)
    return url unless Rails.env.development? && url.to_s.include?("localstack")
    url.sub("http://localstack:4566", ENV.fetch("S3_PUBLIC_ENDPOINT", "http://localhost:4567"))
  end
end
