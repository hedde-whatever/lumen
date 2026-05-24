class Medium < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :path, presence: true

  def presigned_url(expires_in: 3600)
    S3Client.presigned_url(:get_object,
      bucket:     ENV.fetch("S3_BUCKET_NAME"),
      key:        path,
      expires_in: expires_in
    )
  end
end
