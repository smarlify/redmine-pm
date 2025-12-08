# frozen_string_literal: true

# Load S3 storage module
require_dependency 'redmine/s3_storage'

# Monkey patch Attachment model to support S3 storage
module S3AttachmentExtension
  extend ActiveSupport::Concern

  included do
    # Override storage path if S3 is enabled
    after_initialize :configure_s3_storage, if: :s3_enabled?
    after_commit :upload_to_s3, on: :create, if: :s3_enabled?
    after_commit :delete_from_s3, on: :destroy, if: :s3_enabled?
  end

  def s3_enabled?
    Redmine::S3Storage.enabled?
  end

  def s3_key
    return nil unless s3_enabled? && disk_filename.present?
    "#{disk_directory}/#{disk_filename}"
  end

  def s3_url
    return nil unless s3_enabled?
    Redmine::S3Storage.presigned_url(s3_key)
  end

  private

  def configure_s3_storage
    # Keep local storage path for compatibility, but files will be in S3
    # Use tmp directory on Heroku since filesystem is ephemeral
    if Rails.env.production? && ENV['DYNO'].present?
      self.class.storage_path = File.join(Rails.root, "tmp", "files")
    end
  end

  def upload_to_s3
    return unless disk_filename.present?
    
    # Wait for file to be written to disk first
    local_file = original_diskfile
    return unless File.exist?(local_file)

    s3_path = s3_key
    return unless s3_path

    if Redmine::S3Storage.upload_file(local_file, s3_path, content_type)
      Rails.logger.info "Uploaded attachment #{filename} to S3: #{s3_path}"
      # Optionally delete local file after upload (saves space on Heroku)
      if Redmine::Configuration['s3_delete_local_after_upload'] || (Rails.env.production? && ENV['DYNO'].present?)
        begin
          FileUtils.rm_f(local_file) if File.exist?(local_file)
        rescue => e
          Rails.logger.warn "Could not delete local file #{local_file}: #{e.message}"
        end
      end
    else
      Rails.logger.error "Failed to upload attachment #{filename} to S3"
    end
  end

  def delete_from_s3
    return unless s3_key

    if Redmine::S3Storage.delete_file(s3_key)
      Rails.logger.info "Deleted attachment #{filename} from S3: #{s3_key}"
    else
      Rails.logger.warn "Failed to delete attachment #{filename} from S3: #{s3_key}"
    end
  end
end

# Extend Attachment model with S3 support (after app loads)
Rails.application.config.to_prepare do
  Attachment.class_eval do
  include S3AttachmentExtension

  # Override diskfile method to download from S3 if needed
  alias_method :original_diskfile, :diskfile

  def diskfile
    local_path = original_diskfile
    
    # If S3 is enabled and file doesn't exist locally, try to download from S3
    if s3_enabled? && !File.exist?(local_path) && s3_key.present?
      if Redmine::S3Storage.file_exists?(s3_key)
        FileUtils.mkdir_p(File.dirname(local_path))
        if Redmine::S3Storage.download_file(s3_key, local_path)
          Rails.logger.info "Downloaded attachment #{filename} from S3 to #{local_path}"
        end
      end
    end
    
    local_path
  end
  end
end

