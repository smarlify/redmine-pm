# frozen_string_literal: true

require 'fog/aws'

module RedmineBySmarlify
  module Services
    class S3Storage
      def self.enabled?
        access_key_id.present? && secret_access_key.present? && bucket.present?
      end

      def self.access_key_id
        Redmine::Configuration['s3_access_key_id'] || ENV['AWS_ACCESS_KEY_ID']
      end

      def self.secret_access_key
        Redmine::Configuration['s3_secret_access_key'] || ENV['AWS_SECRET_ACCESS_KEY']
      end

      def self.bucket
        Redmine::Configuration['s3_bucket'] || ENV['S3_BUCKET']
      end

      def self.region
        Redmine::Configuration['s3_region'] || ENV['AWS_REGION'] || 'us-east-1'
      end

      def self.endpoint
        Redmine::Configuration['s3_endpoint'] || ENV['S3_ENDPOINT']
      end

      def self.connection
        @connection ||= begin
          return nil unless enabled?

          options = {
            provider: 'AWS',
            aws_access_key_id: access_key_id,
            aws_secret_access_key: secret_access_key,
            region: region
          }

          # Add endpoint for S3-compatible services (e.g., DigitalOcean Spaces)
          options[:endpoint] = endpoint if endpoint.present?

          Fog::Storage.new(options)
        end
      end

      def self.directory
        @directory ||= connection&.directories&.get(bucket) if enabled?
      end

      def self.upload_file(local_path, remote_path, content_type = nil)
        return false unless enabled?

        begin
          file = directory.files.create(
            key: remote_path,
            body: File.open(local_path, 'rb'),
            content_type: content_type || 'application/octet-stream',
            public: false
          )
          file.public_url
        rescue => e
          Rails.logger.error "S3 upload error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          false
        end
      end

      def self.download_file(remote_path, local_path)
        return false unless enabled?

        begin
          file = directory.files.get(remote_path)
          return false unless file

          FileUtils.mkdir_p(File.dirname(local_path))
          File.binwrite(local_path, file.body)
          true
        rescue => e
          Rails.logger.error "S3 download error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          false
        end
      end

      def self.delete_file(remote_path)
        return false unless enabled?

        begin
          file = directory.files.get(remote_path)
          file&.destroy
          true
        rescue => e
          Rails.logger.error "S3 delete error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          false
        end
      end

      def self.file_exists?(remote_path)
        return false unless enabled?

        begin
          directory.files.head(remote_path).present?
        rescue
          false
        end
      end

      def self.presigned_url(remote_path, expires_in = 3600)
        return nil unless enabled?

        begin
          file = directory.files.get(remote_path)
          return nil unless file

          # Generate presigned URL for private files
          file.url(Time.now.to_i + expires_in)
        rescue => e
          Rails.logger.error "S3 presigned URL error: #{e.message}"
          nil
        end
      end
    end
  end
end
