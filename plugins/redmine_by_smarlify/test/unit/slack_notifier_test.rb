# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class SlackNotifierTest < ActiveSupport::TestCase
  def setup
    @original_webhook_url = ENV['SLACK_WEBHOOK_URL']
  end

  def teardown
    ENV['SLACK_WEBHOOK_URL'] = @original_webhook_url
  end

  def test_enabled_when_webhook_url_present
    ENV['SLACK_WEBHOOK_URL'] = 'https://hooks.slack.com/services/test'
    assert RedmineBySmarlify::Services::SlackNotifier.enabled?
  end

  def test_disabled_when_webhook_url_missing
    ENV['SLACK_WEBHOOK_URL'] = nil
    assert_not RedmineBySmarlify::Services::SlackNotifier.enabled?
  end

  def test_webhook_url_from_env
    test_url = 'https://hooks.slack.com/services/test'
    ENV['SLACK_WEBHOOK_URL'] = test_url
    assert_equal test_url, RedmineBySmarlify::Services::SlackNotifier.webhook_url
  end
end
