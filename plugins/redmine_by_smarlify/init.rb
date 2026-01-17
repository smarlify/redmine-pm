# frozen_string_literal: true

require 'redmine'

Redmine::Plugin.register :redmine_by_smarlify do
  name 'Redmine by Smarlify'
  author 'Smarlify Team'
  description 'Adds Smarlify features to Redmine 6.x'
  version '1.0.0'
  url 'https://smarlify.co'
  author_url 'https://smarlify.co'

  # Plugin settings
  settings default: {
    'slack_enabled' => false,
    's3_enabled' => false
  }, partial: 'settings/redmine_by_smarlify'

  # Require plugin libraries after Redmine has loaded
  Rails.application.config.to_prepare do
    require_dependency 'redmine_by_smarlify/patches/mailer_patch'
    require_dependency 'redmine_by_smarlify/patches/attachment_patch'
  end
end
