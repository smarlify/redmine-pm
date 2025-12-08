# frozen_string_literal: true

require 'httparty'

module Redmine
  class SlackNotifier
    include HTTParty

    def self.enabled?
      webhook_url.present?
    end

    def self.webhook_url
      Redmine::Configuration['slack_webhook_url'] || ENV['SLACK_WEBHOOK_URL']
    end

    def self.notify_issue_added(issue, author)
      return unless enabled?

      # Get all notified users
      notified = (issue.notified_users | issue.notified_watchers | issue.notified_mentions).compact.uniq
      message = build_issue_message(issue, author, :added, notified)
      send_message(message)
    end

    def self.notify_issue_updated(issue, journal, author)
      return unless enabled?

      # Get all notified users
      notified = (journal.notified_users | journal.notified_watchers | journal.notified_mentions | issue.notified_mentions).compact.uniq
      message = build_issue_updated_message(issue, journal, author, notified)
      send_message(message)
    end

    def self.notify_issue_comment(issue, journal, author)
      return unless enabled?

      # Get all notified users
      notified = (journal.notified_users | journal.notified_watchers | journal.notified_mentions | issue.notified_mentions).compact.uniq
      message = build_issue_comment_message(issue, journal, author, notified)
      send_message(message)
    end

    def self.notify_document_added(document, author)
      return unless enabled?

      # Get all notified users
      notified = document.notified_users.compact.uniq
      message = build_document_message(document, author, :added, notified)
      send_message(message)
    end

    def self.notify_wiki_content_added(page, author)
      return unless enabled?

      # Get all notified users (from wiki_content, not page)
      wiki_content = page.content
      notified = wiki_content ? (wiki_content.notified_users | page.wiki.notified_watchers).compact.uniq : []
      message = build_wiki_message(page, author, :added, notified)
      send_message(message)
    end

    def self.notify_wiki_content_updated(page, author)
      return unless enabled?

      # Get all notified users (from wiki_content, not page)
      wiki_content = page.content
      notified = wiki_content ? (wiki_content.notified_users | page.wiki.notified_watchers).compact.uniq : []
      message = build_wiki_message(page, author, :updated, notified)
      send_message(message)
    end

    def self.send_test_notification
      return unless enabled?

      message = {
        text: "🔔 Redmine Test Notification",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "🔔 Redmine Test Notification"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "This is a test notification from your Redmine instance. If you're seeing this, Slack integration is working correctly! ✅"
            }
          }
        ]
      }
      send_message(message)
    end

    private

    # Format user mentions for Slack
    # Since Redmine username/email matches Slack user, we can mention them
    def self.format_user_mentions(users)
      return "" if users.blank?
      
      mentions = users.map do |user|
        # Use login (username) for mention, fallback to email
        username = user.login.presence || user.mail&.split('@')&.first
        "@#{username}" if username
      end.compact.uniq
      
      mentions.any? ? "\n\n*Notifying:* #{mentions.join(' ')}" : ""
    end

    def self.build_issue_message(issue, author, action, notified_users = [])
      action_text = action == :added ? "created" : "updated"
      emoji = action == :added ? "🆕" : "📝"
      
      {
        text: "#{emoji} Issue #{action_text}: #{issue.subject}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "#{emoji} Issue #{action_text.capitalize}"
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Project:*\n#{issue.project.name}"
              },
              {
                type: "mrkdwn",
                text: "*Issue ID:*\n##{issue.id}"
              },
              {
                type: "mrkdwn",
                text: "*Tracker:*\n#{issue.tracker.name}"
              },
              {
                type: "mrkdwn",
                text: "*Status:*\n#{issue.status.name}"
              },
              {
                type: "mrkdwn",
                text: "*Priority:*\n#{issue.priority&.name || 'N/A'}"
              },
              {
                type: "mrkdwn",
                text: "*Assigned to:*\n#{issue.assigned_to&.name || 'Unassigned'}"
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Subject:*\n#{issue.subject}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Description:*\n#{issue.description.presence || 'No description'}#{format_user_mentions(notified_users)}"
            }
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "View Issue"
                },
                url: issue_url(issue),
                style: "primary"
              }
            ]
          }
        ]
      }
    end

    def self.build_issue_updated_message(issue, journal, author, notified_users = [])
      changes = journal.details.map do |detail|
        property = detail.prop_key.humanize
        old_value = detail.old_value.presence || 'N/A'
        new_value = detail.value.presence || 'N/A'
        "*#{property}*: #{old_value} → #{new_value}"
      end.join("\n")

      {
        text: "📝 Issue Updated: #{issue.subject}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "📝 Issue Updated"
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Project:*\n#{issue.project.name}"
              },
              {
                type: "mrkdwn",
                text: "*Issue ID:*\n##{issue.id}"
              },
              {
                type: "mrkdwn",
                text: "*Updated by:*\n#{author.name}"
              },
              {
                type: "mrkdwn",
                text: "*Status:*\n#{issue.status.name}"
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Subject:*\n#{issue.subject}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Changes:*\n#{changes.presence || 'No changes tracked'}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Notes:*\n#{journal.notes.presence || 'No notes'}#{format_user_mentions(notified_users)}"
            }
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "View Issue"
                },
                url: issue_url(issue),
                style: "primary"
              }
            ]
          }
        ]
      }
    end

    def self.build_issue_comment_message(issue, journal, author, notified_users = [])
      {
        text: "💬 Comment on Issue: #{issue.subject}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "💬 New Comment"
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Project:*\n#{issue.project.name}"
              },
              {
                type: "mrkdwn",
                text: "*Issue ID:*\n##{issue.id}"
              },
              {
                type: "mrkdwn",
                text: "*Commented by:*\n#{author.name}"
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Subject:*\n#{issue.subject}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Comment:*\n#{journal.notes}#{format_user_mentions(notified_users)}"
            }
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "View Issue"
                },
                url: issue_url(issue),
                style: "primary"
              }
            ]
          }
        ]
      }
    end

    def self.build_document_message(document, author, action, notified_users = [])
      action_text = action == :added ? "added" : "updated"
      emoji = action == :added ? "📄" : "📝"
      
      {
        text: "#{emoji} Document #{action_text}: #{document.title}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "#{emoji} Document #{action_text.capitalize}"
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Project:*\n#{document.project.name}"
              },
              {
                type: "mrkdwn",
                text: "*Category:*\n#{document.category&.name || 'Uncategorized'}"
              },
              {
                type: "mrkdwn",
                text: "*Added by:*\n#{author.name}"
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Title:*\n#{document.title}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Description:*\n#{document.description.presence || 'No description'}#{format_user_mentions(notified_users)}"
            }
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "View Document"
                },
                url: document_url(document),
                style: "primary"
              }
            ]
          }
        ]
      }
    end

    def self.build_wiki_message(page, author, action, notified_users = [])
      action_text = action == :added ? "created" : "updated"
      emoji = action == :added ? "📝" : "✏️"
      
      {
        text: "#{emoji} Wiki page #{action_text}: #{page.title}",
        blocks: [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: "#{emoji} Wiki Page #{action_text.capitalize}"
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Project:*\n#{page.project.name}"
              },
              {
                type: "mrkdwn",
                text: "*#{action_text.capitalize} by:*\n#{author.name}"
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*Title:*\n#{page.title}#{format_user_mentions(notified_users)}"
            }
          },
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  text: "View Wiki Page"
                },
                url: wiki_url(page),
                style: "primary"
              }
            ]
          }
        ]
      }
    end

    def self.issue_url(issue)
      "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
    end

    def self.document_url(document)
      "#{Setting.protocol}://#{Setting.host_name}/documents/#{document.id}"
    end

    def self.wiki_url(page)
      "#{Setting.protocol}://#{Setting.host_name}/projects/#{page.project.identifier}/wiki/#{page.title}"
    end

    def self.send_message(message)
      return false unless webhook_url.present?

      begin
        response = HTTParty.post(
          webhook_url,
          body: message.to_json,
          headers: { 'Content-Type' => 'application/json' },
          timeout: 10
        )

        unless response.success?
          Rails.logger.error "Slack notification failed: #{response.code} - #{response.body}"
        end

        response.success?
      rescue => e
        Rails.logger.error "Slack notification error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        false
      end
    end
  end
end

