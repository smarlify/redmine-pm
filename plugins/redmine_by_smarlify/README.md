# Redmine by Smarlify

A Redmine plugin that adds Slack notifications and S3 file storage support.

## Features

### 1. Slack Notifications

Send real-time notifications to Slack for:
- New issues
- Issue updates and comments
- New documents
- Wiki page changes

Features:
- Rich formatted messages with all issue details
- User mentions/tagging in Slack
- Direct links to Redmine items
- Configurable via webhook URL

### 2. S3 File Storage

Store Redmine attachments in AWS S3 or S3-compatible services:
- Automatic upload to S3 on file attachment
- On-demand download from S3 when accessing files
- Support for AWS S3, DigitalOcean Spaces, and other S3-compatible services
- Optional local file deletion after upload (saves space on Heroku)
- Presigned URLs for secure file access

## Installation

1. Copy the plugin to your Redmine plugins directory:
```bash
cd /path/to/redmine/plugins
git clone git@github.com:smarlify/redmine_by_smarlify.git
```

2. Install dependencies:
```bash
cd /path/to/redmine
bundle install
```

3. Restart your Redmine instance

## Configuration

### Slack Notifications

#### Option A: Via Environment Variables (Recommended for Heroku)

```bash
export SLACK_WEBHOOK_URL="your-slack-webhook-url-here"
```

#### Option B: Via configuration.yml

Add to `config/configuration.yml`:

```yaml
production:
  slack_webhook_url: "your-slack-webhook-url-here"
```

#### Getting a Slack Webhook URL

1. Go to https://api.slack.com/apps
2. Create a new app or select existing one
3. Enable "Incoming Webhooks"
4. Click "Add New Webhook to Workspace"
5. Select the channel where notifications should be posted
6. Copy the webhook URL

#### User Mentions

For user mentions to work in Slack:
- Redmine usernames should match Slack usernames
- Users must be in the Slack channel where notifications are posted

### S3 File Storage

#### Option A: Via Environment Variables (Recommended for Heroku)

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export S3_BUCKET="your-bucket-name"
export AWS_REGION="us-east-1"  # Optional, defaults to us-east-1
export S3_ENDPOINT="https://nyc3.digitaloceanspaces.com"  # Optional, for S3-compatible services
```

#### Option B: Via configuration.yml

Add to `config/configuration.yml`:

```yaml
production:
  s3_access_key_id: your_access_key
  s3_secret_access_key: your_secret_key
  s3_bucket: your-bucket-name
  s3_region: us-east-1
  s3_endpoint: https://nyc3.digitaloceanspaces.com  # Optional
  s3_delete_local_after_upload: true  # Optional, recommended for Heroku
```

#### Using Heroku Bucketeer

```bash
heroku addons:create bucketeer:hobbyist -a your-app
heroku config:set AWS_ACCESS_KEY_ID=$(heroku config:get BUCKETEER_AWS_ACCESS_KEY_ID -a your-app) -a your-app
heroku config:set AWS_SECRET_ACCESS_KEY=$(heroku config:get BUCKETEER_AWS_SECRET_ACCESS_KEY -a your-app) -a your-app
heroku config:set S3_BUCKET=$(heroku config:get BUCKETEER_BUCKET_NAME -a your-app) -a your-app
heroku config:set AWS_REGION=$(heroku config:get BUCKETEER_AWS_REGION -a your-app) -a your-app
```

## Testing

### Test Slack Notifications

```bash
rails console

# In console:
Redmine::SlackNotifier.send_test_notification
```

You should see a test message in your configured Slack channel.

### Test S3 Storage

1. Upload a file to any issue in Redmine
2. Check your S3 bucket - the file should be there
3. Download the file from Redmine - it should work seamlessly

## How It Works

### Slack Notifications

The plugin hooks into Redmine's `Mailer` class to intercept notification events. When an event occurs (new issue, comment, etc.), the plugin:

1. Collects all users who should be notified
2. Formats a rich Slack message with all relevant details
3. Sends the message to the configured webhook URL
4. Mentions users in Slack using their Redmine username

### S3 File Storage

The plugin extends Redmine's `Attachment` model to:

1. **On Upload**: Automatically upload files to S3 after they're saved locally
2. **On Download**: Check if file exists locally; if not, download from S3
3. **On Delete**: Remove files from both local storage and S3

Files are organized in S3 by date: `YYYY/MM/filename`

## Troubleshooting

### Slack Notifications Not Working

1. Verify webhook URL is correct:
```bash
heroku config:get SLACK_WEBHOOK_URL -a your-app
```

2. Check Redmine logs for errors:
```bash
tail -f log/production.log | grep Slack
```

3. Test webhook manually:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  YOUR_WEBHOOK_URL
```

### S3 Storage Not Working

1. Verify credentials are correct:
```bash
heroku config | grep AWS
```

2. Check S3 bucket exists and is accessible

3. Check Redmine logs:
```bash
tail -f log/production.log | grep S3
```

### Users Not Being Tagged in Slack

- Verify Redmine usernames match Slack usernames
- Ensure users are in the Slack channel where notifications are posted
- Check that users have email addresses set in Redmine

## Migration from Local Files

If you have existing files in local filesystem and want to migrate to S3:

```bash
rails console

# Migrate all attachments
Attachment.find_each do |att|
  local_file = att.diskfile
  if File.exist?(local_file) && att.s3_key.present?
    unless Redmine::S3Storage.file_exists?(att.s3_key)
      Redmine::S3Storage.upload_file(local_file, att.s3_key, att.content_type)
      puts "Migrated: #{att.filename}"
    end
  end
end
```

## License

This plugin is licensed under the MIT License.

## Support

For issues, questions, or contributions, please visit:
- GitHub: https://github.com/smarlify/redmine_by_smarlify
- Website: https://smarlify.co

## Credits

Developed by the Smarlify Team with ❤️
