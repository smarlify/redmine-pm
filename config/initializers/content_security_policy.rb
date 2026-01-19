# frozen_string_literal: true

# Content Security Policy configuration for iframe embedding
# This allows Redmine to be embedded in iframes from trusted domains
Rails.application.config.content_security_policy do |policy|
  # If ALLOW_ALL_IFRAME_DOMAINS is set to 'true', disable frame_ancestors restriction
  # (WARNING: Only use for testing! This allows embedding from any domain)
  if ENV['ALLOW_ALL_IFRAME_DOMAINS'] == 'true'
    # Don't set frame_ancestors at all, which allows all domains
    # This is for testing only - remove in production!
  else
    # Build list of trusted domains for iframe embedding
    trusted_domains = []
    
    # Default trusted domains
    trusted_domains << 'https://easy-redmine-app-01fc62f8c1f4.herokuapp.com'
    trusted_domains << 'https://app.easysoftware.com'
    
    # Allow localhost for local development/testing (even in production)
    # This is useful when testing EasyRedmineApp locally against production Redmine
    trusted_domains << 'http://localhost:3000'
    trusted_domains << 'http://127.0.0.1:3000'
    
    # Add domains from environment variable if set (comma-separated)
    # Example: REDMINE_TRUSTED_IFRAME_DOMAINS="https://app1.example.com,https://app2.example.com"
    if ENV['REDMINE_TRUSTED_IFRAME_DOMAINS'].present?
      trusted_domains.concat(ENV['REDMINE_TRUSTED_IFRAME_DOMAINS'].split(',').map(&:strip))
    end
    
    # Allow iframe embedding from trusted domains and self
    # :self allows embedding from the same origin (pm.smarlify.co)
    if trusted_domains.any?
      policy.frame_ancestors :self, *trusted_domains
    else
      # If no trusted domains configured, only allow self
      policy.frame_ancestors :self
    end
  end
end

# Report CSP violations (optional, for debugging)
# Uncomment to enable report-only mode (won't block, just report violations)
# Rails.application.config.content_security_policy_report_only = false
