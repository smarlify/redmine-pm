# Deploy Slack Notifications to Heroku

## Quick Deployment Steps

### 1. Get Slack Webhook URL

1. Go to https://api.slack.com/apps
2. Select your Smarlify workspace app (or create new one)
3. Go to "Incoming Webhooks"
4. Enable "Activate Incoming Webhooks" if not already enabled
5. Click "Add New Webhook to Workspace"
6. Select the `#redminebot` channel (or create it first)
7. Copy the webhook URL (format: `https://hooks.slack.com/services/...`)

### 2. Configure on Heroku

```bash
# Set the Slack webhook URL
heroku config:set SLACK_WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE" -a redmine-pm

# Verify it's set
heroku config:get SLACK_WEBHOOK_URL -a redmine-pm
```

### 3. Deploy Code

```bash
# Make sure you're on the slack-notifications branch
git checkout slack-notifications

# Commit all changes
git add .
git commit -m "Add Slack notifications with user tagging"

# Push to Heroku
git push heroku slack-notifications:main

# Or if you've merged to main:
# git push heroku main
```

### 4. Restart Heroku App

```bash
heroku restart -a redmine-pm
```

### 5. Test the Integration

```bash
# Test Slack notification
heroku run rails console -a redmine-pm

# In the console:
Redmine::SlackNotifier.send_test_notification
```

You should see a test message in your `#redminebot` channel.

### 6. Test with Real Issue

1. Create a new issue in Redmine
2. Assign it to a user (make sure their Redmine login matches their Slack username)
3. Check `#redminebot` channel - you should see:
   - Notification about the new issue
   - User mentions like `@username` for all notified users

## How User Tagging Works

- Redmine users are mentioned in Slack using their Redmine `login` (username)
- Format: `@username` in the notification
- Make sure Redmine usernames match Slack usernames for proper tagging
- If a user's Redmine login is `john.doe`, they'll be mentioned as `@john.doe` in Slack

## Troubleshooting

### Notifications Not Appearing

1. Check webhook URL is correct:
```bash
heroku config:get SLACK_WEBHOOK_URL -a redmine-pm
```

2. Check logs:
```bash
heroku logs --tail -a redmine-pm | grep Slack
```

3. Test webhook manually:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test from Heroku"}' \
  YOUR_WEBHOOK_URL
```

### Users Not Being Tagged

- Verify Redmine usernames match Slack usernames
- Check that users are in the `#redminebot` channel (Slack only tags users who are in the channel)
- Verify users have email addresses set in Redmine

## Email Notifications

- Email notifications will still attempt to send
- They will fail silently if SMTP is not configured (as configured in production.rb)
- Slack notifications work independently and don't require email to be configured

