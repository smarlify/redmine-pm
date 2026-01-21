# frozen_string_literal: true

# Content Security Policy for iframe embedding
Rails.application.config.content_security_policy do |policy|
  trusted = %w[
    https://easy-redmine-app-01fc62f8c1f4.herokuapp.com
    https://app.easysoftware.com
  ]

  # Allow local testing from the companion app
  if Rails.env.development?
    trusted << 'http://localhost:3000'
    trusted << 'http://127.0.0.1:3000'
  end

  if ENV['REDMINE_TRUSTED_IFRAME_DOMAINS'].present?
    trusted.concat(ENV['REDMINE_TRUSTED_IFRAME_DOMAINS'].split(',').map(&:strip))
  end

  policy.frame_ancestors :self, *trusted
end
