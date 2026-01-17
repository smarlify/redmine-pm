# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class S3StorageTest < ActiveSupport::TestCase
  def setup
    @original_access_key = ENV['AWS_ACCESS_KEY_ID']
    @original_secret_key = ENV['AWS_SECRET_ACCESS_KEY']
    @original_bucket = ENV['S3_BUCKET']
  end

  def teardown
    ENV['AWS_ACCESS_KEY_ID'] = @original_access_key
    ENV['AWS_SECRET_ACCESS_KEY'] = @original_secret_key
    ENV['S3_BUCKET'] = @original_bucket
  end

  def test_enabled_when_credentials_present
    ENV['AWS_ACCESS_KEY_ID'] = 'test_key'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'test_secret'
    ENV['S3_BUCKET'] = 'test-bucket'
    assert RedmineBySmarlify::Services::S3Storage.enabled?
  end

  def test_disabled_when_credentials_missing
    ENV['AWS_ACCESS_KEY_ID'] = nil
    ENV['AWS_SECRET_ACCESS_KEY'] = nil
    ENV['S3_BUCKET'] = nil
    assert_not RedmineBySmarlify::Services::S3Storage.enabled?
  end

  def test_access_key_id_from_env
    test_key = 'test_access_key'
    ENV['AWS_ACCESS_KEY_ID'] = test_key
    assert_equal test_key, RedmineBySmarlify::Services::S3Storage.access_key_id
  end

  def test_default_region
    assert_equal 'us-east-1', RedmineBySmarlify::Services::S3Storage.region
  end
end
