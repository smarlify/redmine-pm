# S3 File Storage & Slack Notifications Setup

This document explains how to configure S3 file storage and Slack notifications for Redmine on Heroku.

## Quick Start

### 1. Install Dependencies

After pulling these changes, run:

```bash
bundle install
```

This will install:
- `fog-aws` - For S3 file storage
- `httparty` - For Slack webhook notifications

### 2. Configure S3 File Storage

Choose one of the following options:

#### Option A: AWS S3

```bash
heroku config:set AWS_ACCESS_KEY_ID=your_key -a redmine-pm
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret -a redmine-pm
heroku config:set S3_BUCKET=your-bucket-name -a redmine-pm
heroku config:set AWS_REGION=us-east-1 -a redmine-pm
```

#### Option B: Heroku Bucketeer (Easiest)

```bash
heroku addons:create bucketeer:hobbyist -a redmine-pm
heroku config:set AWS_ACCESS_KEY_ID=$(heroku config:get BUCKETEER_AWS_ACCESS_KEY_ID -a redmine-pm) -a redmine-pm
heroku config:set AWS_SECRET_ACCESS_KEY=$(heroku config:get BUCKETEER_AWS_SECRET_ACCESS_KEY -a redmine-pm) -a redmine-pm
heroku config:set S3_BUCKET=$(heroku config:get BUCKETEER_BUCKET_NAME -a redmine-pm) -a redmine-pm
heroku config:set AWS_REGION=$(heroku config:get BUCKETEER_AWS_REGION -a redmine-pm) -a redmine-pm
```

### 3. Configure Slack Notifications

1. Create a Slack webhook: https://api.slack.com/apps → Create App → Incoming Webhooks
2. Copy the webhook URL
3. Set it in Heroku:

```bash
heroku config:set SLACK_WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE" -a redmine-pm
```

### 4. Restart the App

```bash
heroku restart -a redmine-pm
```

### 5. Test the Integration

```bash
# Test Slack
heroku run rails console -a redmine-pm
Redmine::SlackNotifier.send_test_notification

# Test S3 (upload a file in Redmine UI and check S3 bucket)
```

## How It Works

### S3 File Storage

- When S3 is configured, all file uploads are automatically stored in S3
- Files are organized by date: `YYYY/MM/filename`
- Local files are optionally deleted after upload (saves space on Heroku)
- Files are downloaded from S3 on-demand when accessed

### Slack Notifications

- When Slack webhook is configured, notifications are sent to Slack for:
  - New issues
  - Issue updates and comments
  - New documents
  - Wiki page changes
- Slack notifications work **in addition to** email (if configured) or **instead of** email (if SMTP is not configured)

## Configuration Options

### Via Environment Variables (Heroku)

```bash
# S3
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
S3_BUCKET
AWS_REGION
S3_ENDPOINT (optional, for S3-compatible services)

# Slack
SLACK_WEBHOOK_URL
```

### Via configuration.yml

Create `config/configuration.yml` (copy from `config/configuration.yml.example`):

```yaml
production:
  s3_access_key_id: your_key
  s3_secret_access_key: your_secret
  s3_bucket: your-bucket
  s3_region: us-east-1
  slack_webhook_url: YOUR_WEBHOOK_URL_HERE
```

## Troubleshooting

### Files Not Uploading to S3

1. Check S3 credentials are correct:
```bash
heroku config | grep AWS
```

2. Check S3 bucket exists and is accessible
3. Check logs:
```bash
heroku logs --tail -a redmine-pm | grep S3
```

### Slack Notifications Not Working

1. Verify webhook URL is correct:
```bash
heroku config:get SLACK_WEBHOOK_URL -a redmine-pm
```

2. Test webhook manually:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  YOUR_WEBHOOK_URL
```

3. Check logs:
```bash
heroku logs --tail -a redmine-pm | grep Slack
```

## Migration from Local Files

If you have existing files in the local filesystem:

1. Configure S3
2. Files will be uploaded to S3 on next access (lazy migration)
3. Or manually migrate:
```bash
heroku run rails console -a redmine-pm
Attachment.find_each do |att|
  if File.exist?(att.diskfile) && !Redmine::S3Storage.file_exists?(att.s3_key)
    Redmine::S3Storage.upload_file(att.diskfile, att.s3_key, att.content_type)
  end
end
```

## Cost Considerations

### S3 Costs
- AWS S3: ~$0.023/GB/month storage + $0.005/1000 requests
- Heroku Bucketeer: $5/month (hobbyist) includes 25GB storage
- DigitalOcean Spaces: $5/month for 250GB

### Slack
- Free tier: Unlimited webhooks and messages

## Security Notes

- Never commit `configuration.yml` with credentials to git
- Use Heroku config vars for sensitive data
- S3 bucket should be private (not public)
- Slack webhook URLs are secret - don't share publicly

