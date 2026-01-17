# frozen_string_literal: true

require_dependency 'redmine_by_smarlify/services/slack_notifier'

module RedmineBySmarlify
  module Patches
    module MailerPatch
      def self.included(base)
        base.class_eval do
          # Override deliver_issue_add to also send Slack notification
          class << self
            alias_method :original_deliver_issue_add, :deliver_issue_add

            def deliver_issue_add(issue)
              original_deliver_issue_add(issue)
              # Send Slack notification (only once, not per user)
              # Emails will still try to send but fail silently if SMTP not configured
              if RedmineBySmarlify::Services::SlackNotifier.enabled? && issue.author
                RedmineBySmarlify::Services::SlackNotifier.notify_issue_added(issue, issue.author)
              end
            end

            alias_method :original_deliver_issue_edit, :deliver_issue_edit

            def deliver_issue_edit(journal)
              original_deliver_issue_edit(journal)
              # Send Slack notification (only once, not per user)
              if RedmineBySmarlify::Services::SlackNotifier.enabled? && journal.user
                issue = journal.journalized
                if journal.notes.present?
                  RedmineBySmarlify::Services::SlackNotifier.notify_issue_comment(issue, journal, journal.user)
                else
                  RedmineBySmarlify::Services::SlackNotifier.notify_issue_updated(issue, journal, journal.user)
                end
              end
            end

            alias_method :original_deliver_document_added, :deliver_document_added

            def deliver_document_added(document, author)
              original_deliver_document_added(document, author)
              # Send Slack notification
              if RedmineBySmarlify::Services::SlackNotifier.enabled? && author
                RedmineBySmarlify::Services::SlackNotifier.notify_document_added(document, author)
              end
            end

            alias_method :original_deliver_wiki_content_added, :deliver_wiki_content_added

            def deliver_wiki_content_added(wiki_content)
              original_deliver_wiki_content_added(wiki_content)
              # Send Slack notification
              # Emails will still try to send but fail silently if SMTP not configured
              if RedmineBySmarlify::Services::SlackNotifier.enabled? && wiki_content.author
                RedmineBySmarlify::Services::SlackNotifier.notify_wiki_content_added(wiki_content.page, wiki_content.author)
              end
            end

            alias_method :original_deliver_wiki_content_updated, :deliver_wiki_content_updated

            def deliver_wiki_content_updated(wiki_content)
              original_deliver_wiki_content_updated(wiki_content)
              # Send Slack notification
              # Emails will still try to send but fail silently if SMTP not configured
              if RedmineBySmarlify::Services::SlackNotifier.enabled? && wiki_content.author
                RedmineBySmarlify::Services::SlackNotifier.notify_wiki_content_updated(wiki_content.page, wiki_content.author)
              end
            end
          end
        end
      end
    end
  end
end

# Apply the patch to Mailer
Mailer.include(RedmineBySmarlify::Patches::MailerPatch)
