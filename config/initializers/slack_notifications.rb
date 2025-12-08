# frozen_string_literal: true

# Load Slack notifier
require Rails.root.join('lib', 'redmine', 'slack_notifier')

# Hook into Mailer class methods to send Slack notifications
Mailer.class_eval do
  # Override deliver_issue_add to also send Slack notification
  class << self
    alias_method :original_deliver_issue_add, :deliver_issue_add

    def deliver_issue_add(issue)
      original_deliver_issue_add(issue)
      # Send Slack notification (only once, not per user)
      # Emails will still try to send but fail silently if SMTP not configured
      if Redmine::SlackNotifier.enabled? && issue.author
        Redmine::SlackNotifier.notify_issue_added(issue, issue.author)
      end
    end

    alias_method :original_deliver_issue_edit, :deliver_issue_edit

    def deliver_issue_edit(journal)
      original_deliver_issue_edit(journal)
      # Send Slack notification (only once, not per user)
      if Redmine::SlackNotifier.enabled? && journal.user
        issue = journal.journalized
        if journal.notes.present?
          Redmine::SlackNotifier.notify_issue_comment(issue, journal, journal.user)
        else
          Redmine::SlackNotifier.notify_issue_updated(issue, journal, journal.user)
        end
      end
    end

    alias_method :original_deliver_document_added, :deliver_document_added

    def deliver_document_added(document, author)
      original_deliver_document_added(document, author)
      # Send Slack notification
      if Redmine::SlackNotifier.enabled? && author
        Redmine::SlackNotifier.notify_document_added(document, author)
      end
    end

    alias_method :original_deliver_wiki_content_added, :deliver_wiki_content_added

    def deliver_wiki_content_added(wiki_content)
      original_deliver_wiki_content_added(wiki_content)
      # Send Slack notification
      # Emails will still try to send but fail silently if SMTP not configured
      if Redmine::SlackNotifier.enabled? && wiki_content.author
        Redmine::SlackNotifier.notify_wiki_content_added(wiki_content.page, wiki_content.author)
      end
    end

    alias_method :original_deliver_wiki_content_updated, :deliver_wiki_content_updated

    def deliver_wiki_content_updated(wiki_content)
      original_deliver_wiki_content_updated(wiki_content)
      # Send Slack notification
      # Emails will still try to send but fail silently if SMTP not configured
      if Redmine::SlackNotifier.enabled? && wiki_content.author
        Redmine::SlackNotifier.notify_wiki_content_updated(wiki_content.page, wiki_content.author)
      end
    end
  end
  end
end

