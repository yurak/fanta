module Teams
  class LogoUploader < ApplicationService
    ALLOWED_TYPES = %w[image/png image/jpeg image/jpg].freeze
    MAX_SIZE = 5.megabytes
    MAX_LOGOS = 30
    TARGET_SIZE = 200
    S3_PREFIX = 'user_logos'.freeze

    class InvalidFile < StandardError; end

    def initialize(user:, file:)
      @user = user
      @file = file
    end

    def call
      validate!
      url = upload_to_s3(resize_to_square)
      @user.user_logos.create!(url: url, status: :pending)
    end

    private

    def validate!
      raise InvalidFile, 'Unsupported file type' unless ALLOWED_TYPES.include?(@file.content_type)
      raise InvalidFile, 'File is too large' if @file.size > MAX_SIZE
      raise InvalidFile, 'Logo collection limit reached' if @user.user_logos.kept.count >= MAX_LOGOS
    end

    def resize_to_square
      image = MiniMagick::Image.read(@file.read)
      image.format('png')
      image.combine_options do |c|
        c.resize "#{TARGET_SIZE}x#{TARGET_SIZE}"
        c.background 'none'
        c.gravity 'Center'
        c.extent "#{TARGET_SIZE}x#{TARGET_SIZE}"
        c.strip
      end
      image
    rescue MiniMagick::Error, MiniMagick::Invalid => e
      Rails.logger.error("[Teams::LogoUploader] image processing failed: #{e.class}: #{e.message}")
      raise InvalidFile, 'File is not a valid image'
    end

    def upload_to_s3(image)
      key = "#{S3_PREFIX}/#{@user.id}/#{SecureRandom.hex(12)}.png"
      S3Storage.client.put_object(
        bucket: S3Storage.bucket,
        key: key,
        body: image.to_blob,
        content_type: 'image/png',
        acl: 'public-read'
      )
      "#{S3Storage.bucket_url}/#{key}"
    end
  end
end
