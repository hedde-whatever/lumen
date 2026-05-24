class S3UploadService
  def self.upload(file:, user_id:, event_id:)
    key = "uploads/users/#{user_id}/events/#{event_id}/#{SecureRandom.uuid}-#{file.original_filename}"
    S3Client.client.put_object(
      bucket:       ENV.fetch("S3_BUCKET_NAME"),
      key:          key,
      body:         file.read,
      content_type: file.content_type
    )
    key
  end

  def self.delete(key:)
    S3Client.client.delete_object(
      bucket: ENV.fetch("S3_BUCKET_NAME"),
      key:    key
    )
  end
end
