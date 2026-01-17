# Heroku Deployment Guide for Redmine

This guide will help you deploy Redmine to Heroku.

## Prerequisites

1. Heroku account (sign up at https://www.heroku.com)
2. Heroku CLI installed (https://devcenter.heroku.com/articles/heroku-cli)
3. Git repository initialized

## Initial Setup

### 1. Install Heroku CLI and Login

```bash
# Install Heroku CLI (if not already installed)
# macOS: brew tap heroku/brew && brew install heroku
# Or download from https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login
```

### 2. Create Heroku App

```bash
cd /Users/dave/Development/_Smarlify/Redmine-PM

# Create a new Heroku app
heroku create redmine-pm

# Add Heroku remote (if not automatically added)
heroku git:remote -a redmine-pm
```

### 3. Add PostgreSQL Database

Heroku provides PostgreSQL as an addon. Add it to your app:

```bash
# Add the free tier PostgreSQL database
heroku addons:create heroku-postgresql:essential-0 -a redmine-pm

# Database will be automatically configured via DATABASE_URL
```

### 4. Configure Environment Variables

Set required environment variables:

```bash
# Set Rails environment
heroku config:set RAILS_ENV=production -a redmine-pm

# Enable static file serving
heroku config:set RAILS_SERVE_STATIC_FILES=true -a redmine-pm

# Set secret key base
heroku config:set SECRET_KEY_BASE=$(openssl rand -hex 64) -a redmine-pm
```

### 5. Deploy to Heroku

```bash
# Make sure you're on the heroku-deployment branch (or your deployment branch)
git checkout heroku-deployment

# Push to Heroku (migrations run automatically via Procfile release task)
git push heroku heroku-deployment:main
```

The deployment will automatically:
- Run database migrations via the `release` task in Procfile
- Build and deploy the application

### 6. Load Default Redmine Data

After successful deployment, load default data (locales, roles, etc.):

```bash
# Load default data with English language
echo "en" | heroku run rake redmine:load_default_data -a redmine-pm

# Or for interactive selection:
heroku run rake redmine:load_default_data -a redmine-pm
# Then type your preferred language code (e.g., 'en', 'cs', 'de', etc.)
```

### 7. Create Admin User

```bash
# Open Rails console on Heroku
heroku run rails console -a redmine-pm

# Then in the console, create an admin user:
# user = User.new(:login => "admin", :password => "yourpassword", :password_confirmation => "yourpassword", :firstname => "Admin", :lastname => "User", :mail => "admin@example.com")
# user.admin = true
# user.save!
```

### 8. Restart the Application (if needed)

```bash
heroku restart -a redmine-pm
```

### 9. Open Your App

```bash
heroku open -a redmine-pm
```

Your app should now be available at: `https://redmine-pm-5d4237b8234b.herokuapp.com/`

## Important Notes

### Database Configuration

The `config/database.yml` file uses Heroku's `DATABASE_URL` environment variable automatically. The production configuration is:

```yaml
production:
  url: <%= ENV['DATABASE_URL'] %>
```

Heroku sets `DATABASE_URL` automatically when you add the PostgreSQL addon.

### Static Assets

Static file serving is enabled in production for Heroku via `RAILS_SERVE_STATIC_FILES=true`. If you want to use a CDN or asset host, you can configure it in `config/environments/production.rb`.

### File Storage (S3 Configuration)

Redmine stores uploaded files in the `files/` directory by default. On Heroku, the filesystem is ephemeral, meaning files will be lost on each deploy. **This project includes built-in S3 support** to solve this issue.

#### Option 1: AWS S3 (Recommended)

1. **Create an S3 bucket** in AWS:
   - Go to AWS S3 Console
   - Create a new bucket (e.g., `redmine-pm-files`)
   - Note the region (e.g., `us-east-1`)

2. **Create IAM user with S3 access**:
   - Go to AWS IAM Console
   - Create a new user with programmatic access
   - Attach policy: `AmazonS3FullAccess` (or create custom policy for your bucket only)
   - Save the Access Key ID and Secret Access Key

3. **Configure S3 in Heroku**:
```bash
# Set S3 credentials
heroku config:set AWS_ACCESS_KEY_ID=your_access_key_id -a redmine-pm
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret_access_key -a redmine-pm
heroku config:set S3_BUCKET=redmine-pm-files -a redmine-pm
heroku config:set AWS_REGION=us-east-1 -a redmine-pm
```

4. **Or configure via configuration.yml**:
   - Create `config/configuration.yml` (copy from `configuration.yml.example`)
   - Add S3 settings:
```yaml
production:
  s3_access_key_id: your_access_key_id
  s3_secret_access_key: your_secret_access_key
  s3_bucket: redmine-pm-files
  s3_region: us-east-1
```

#### Option 2: DigitalOcean Spaces (S3-Compatible)

DigitalOcean Spaces is S3-compatible and often cheaper:

```bash
heroku config:set AWS_ACCESS_KEY_ID=your_spaces_key -a redmine-pm
heroku config:set AWS_SECRET_ACCESS_KEY=your_spaces_secret -a redmine-pm
heroku config:set S3_BUCKET=your-space-name -a redmine-pm
heroku config:set AWS_REGION=nyc3 -a redmine-pm
heroku config:set S3_ENDPOINT=https://nyc3.digitaloceanspaces.com -a redmine-pm
```

#### Option 3: Heroku Bucketeer Addon

```bash
# Add Bucketeer addon (provides S3-compatible storage)
heroku addons:create bucketeer:hobbyist -a redmine-pm

# Bucketeer automatically sets these env vars:
# BUCKETEER_AWS_ACCESS_KEY_ID
# BUCKETEER_AWS_SECRET_ACCESS_KEY
# BUCKETEER_BUCKET_NAME
# BUCKETEER_AWS_REGION

# Map to our S3 config vars
heroku config:set AWS_ACCESS_KEY_ID=$(heroku config:get BUCKETEER_AWS_ACCESS_KEY_ID -a redmine-pm) -a redmine-pm
heroku config:set AWS_SECRET_ACCESS_KEY=$(heroku config:get BUCKETEER_AWS_SECRET_ACCESS_KEY -a redmine-pm) -a redmine-pm
heroku config:set S3_BUCKET=$(heroku config:get BUCKETEER_BUCKET_NAME -a redmine-pm) -a redmine-pm
heroku config:set AWS_REGION=$(heroku config:get BUCKETEER_AWS_REGION -a redmine-pm) -a redmine-pm
```

**Note**: After configuring S3, restart your app:
```bash
heroku restart -a redmine-pm
```

### Email Configuration

To send emails from Redmine on Heroku, configure SMTP settings:

```bash
# Add SendGrid addon (free tier available)
heroku addons:create sendgrid:starter -a redmine-pm

# Or configure custom SMTP
heroku config:set SMTP_HOST=smtp.example.com -a redmine-pm
heroku config:set SMTP_PORT=587 -a redmine-pm
heroku config:set SMTP_USERNAME=your-username -a redmine-pm
heroku config:set SMTP_PASSWORD=your-password -a redmine-pm
```

Then configure in Redmine admin panel: Administration → Settings → Email notifications

### Slack Notifications (Alternative to Email)

**This project includes built-in Slack notifications** that can replace or complement email notifications. This is often easier to set up than SMTP on Heroku.

#### Setup Slack Webhook

1. **Create a Slack App**:
   - Go to https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name it (e.g., "Redmine Notifications") and select your workspace

2. **Enable Incoming Webhooks**:
   - In your app settings, go to "Incoming Webhooks"
   - Toggle "Activate Incoming Webhooks" to ON
   - Click "Add New Webhook to Workspace"
   - Select the channel where notifications should go (e.g., `#redmine-notifications`)
   - Copy the Webhook URL

3. **Configure in Heroku**:
```bash
heroku config:set SLACK_WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE" -a redmine-pm
```

4. **Or configure via configuration.yml**:
```yaml
production:
  slack_webhook_url: YOUR_WEBHOOK_URL_HERE
```

5. **Test the integration**:
```bash
heroku run rails console -a redmine-pm
# Then in console:
Redmine::SlackNotifier.send_test_notification
```

**Note**: When Slack webhook is configured, Redmine will send notifications to Slack for:
- New issues
- Issue updates and comments
- New documents
- Wiki page changes

You can use Slack notifications **instead of** email (if SMTP is not configured) or **in addition to** email (if both are configured).

### Scaling

For production use, consider:

```bash
# Scale up web dynos
heroku ps:scale web=1 -a redmine-pm

# For better performance, use Standard dynos
heroku ps:resize web=standard-1x -a redmine-pm
```

### Monitoring

```bash
# View logs
heroku logs --tail -a redmine-pm

# Check app status
heroku ps -a redmine-pm

# View config vars
heroku config -a redmine-pm
```

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues:

```bash
# Check database URL
heroku config:get DATABASE_URL -a redmine-pm

# Test database connection
heroku run rails db -a redmine-pm
```

### App Crashes

If the app crashes, check logs:

```bash
heroku logs --tail -a redmine-pm
```

Common issues:
- **Puma configuration errors**: Check `config/puma.rb` - ensure no Rails-specific methods are used
- **Database migrations**: Ensure migrations run successfully
- **Missing environment variables**: Check all required config vars are set

### Asset Precompilation

If assets aren't loading:

```bash
# Precompile assets manually
heroku run rake assets:precompile -a redmine-pm
```

### Memory Issues

If you encounter memory issues, consider:

1. Upgrading to a larger dyno
2. Reducing worker processes in `config/puma.rb`
3. Using a memory-efficient cache store

## Updating Your Deployment

After making changes:

```bash
# Commit your changes
git add .
git commit -m "Your commit message"
git push origin heroku-deployment

# Deploy to Heroku (migrations run automatically)
git push heroku heroku-deployment:main

# If you need to run additional tasks:
heroku run rake db:migrate -a redmine-pm  # if you have new migrations
heroku restart -a redmine-pm  # if needed
```

## Current Deployment Status

- **App Name**: redmine-pm
- **URL**: https://redmine-pm-5d4237b8234b.herokuapp.com/
- **Database**: PostgreSQL (Heroku Postgres essential-0)
- **Ruby Version**: 3.3.3
- **Rails Version**: 8.0.4

## Additional Resources

- [Heroku Ruby Support](https://devcenter.heroku.com/articles/ruby-support)
- [Heroku PostgreSQL](https://devcenter.heroku.com/articles/heroku-postgresql)
- [Redmine Installation Guide](https://www.redmine.org/projects/redmine/wiki/RedmineInstall)
