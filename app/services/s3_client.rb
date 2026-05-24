class S3Client
  def self.client
    @client ||= Aws::S3::Client.new(
      region:            ENV.fetch("AWS_REGION"),
      access_key_id:     ENV.fetch("AWS_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
      **endpoint_options
    )
  end

  def self.presigned_url(operation, **kwargs)
    url = Aws::S3::Presigner.new(client: client).presigned_url(operation, **kwargs)
    rewrite_localstack_host(url)
  end

  def self.reset!
    @client = nil
  end

  private

  def self.endpoint_options
    endpoint = ENV["S3_ENDPOINT"]
    return {} if endpoint.blank?

    {
      endpoint:         endpoint,
      force_path_style: ENV.fetch("S3_FORCE_PATH_STYLE", "false") == "true"
    }
  end

  # Presigned URLs generated against localstack:4566 are unreachable from the
  # host machine. Rewrite the host so browsers and the frontend can fetch them.
  def self.rewrite_localstack_host(url)
    return url unless Rails.env.development? && url.include?("localstack")

    url.sub("http://localstack:4566", "http://localhost:4566")
  end
end
