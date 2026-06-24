require 'aws-sdk-s3'

module S3Storage
  module_function

  DEFAULT_REGION = 'eu-west-1'.freeze

  def client
    Aws::S3::Client.new(
      region: config[:region] || DEFAULT_REGION,
      access_key_id: config[:access_key_id],
      secret_access_key: config[:secret_access_key]
    )
  end

  def bucket
    config[:bucket]
  end

  def bucket_url
    config[:bucket_url]
  end

  def config
    Rails.application.credentials.aws
  end
end
