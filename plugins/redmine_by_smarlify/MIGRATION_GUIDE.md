# Migration Guide: Core Redmine to Plugin

This document explains the migration from custom core Redmine modifications to the "Redmine by Smarlify" plugin.

## What Changed

### Before (Custom Core Modifications)
- Custom code was directly integrated into Redmine core:
  - `lib/redmine/slack_notifier.rb`
  - `lib/redmine/s3_storage.rb`
  - `config/initializers/slack_notifications.rb`
  - `config/initializers/s3_storage.rb`
- Dependencies (`httparty`, `fog-aws`) were in the main `Gemfile`

### After (Plugin Architecture)
- All custom code is now in a proper Redmine plugin:
  - `plugins/redmine_by_smarlify/`
- Dependencies are managed by the plugin's own `Gemfile`
- Core Redmine remains clean and maintainable

## File Mapping

| Old Location | New Location |
|--------------|--------------|
| `lib/redmine/slack_notifier.rb` | `plugins/redmine_by_smarlify/lib/redmine_by_smarlify/services/slack_notifier.rb` |
| `lib/redmine/s3_storage.rb` | `plugins/redmine_by_smarlify/lib/redmine_by_smarlify/services/s3_storage.rb` |
| `config/initializers/slack_notifications.rb` | `plugins/redmine_by_smarlify/lib/redmine_by_smarlify/patches/mailer_patch.rb` |
| `config/initializers/s3_storage.rb` | `plugins/redmine_by_smarlify/lib/redmine_by_smarlify/patches/attachment_patch.rb` |

## Namespace Changes

### Slack Notifier
- **Old:** `Redmine::SlackNotifier`
- **New:** `RedmineBySmarlify::Services::SlackNotifier`

### S3 Storage
- **Old:** `Redmine::S3Storage`
- **New:** `RedmineBySmarlify::Services::S3Storage`

## Configuration

Configuration remains the same! No changes needed to:
- `config/configuration.yml`
- Environment variables (`SLACK_WEBHOOK_URL`, `AWS_ACCESS_KEY_ID`, etc.)

## Deployment Steps

### 1. Update Dependencies

```bash
cd /path/to/redmine
bundle install
```

This will install the plugin's dependencies from `plugins/redmine_by_smarlify/Gemfile`.

### 2. Restart Redmine

```bash
# For development
rails server

# For production (Heroku)
heroku restart -a your-app-name
```

### 3. Verify Plugin is Loaded

```bash
rails console

# Check if plugin is registered
Redmine::Plugin.registered_plugins[:redmine_by_smarlify]

# Test Slack notifications
RedmineBySmarlify::Services::SlackNotifier.send_test_notification

# Check S3 storage
RedmineBySmarlify::Services::S3Storage.enabled?
```

## Testing

Run the plugin tests:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=redmine_by_smarlify
```

## Rollback (If Needed)

If you need to rollback to the old core modifications:

1. Restore the deleted files from Git:
```bash
git checkout HEAD~1 -- lib/redmine/slack_notifier.rb
git checkout HEAD~1 -- lib/redmine/s3_storage.rb
git checkout HEAD~1 -- config/initializers/slack_notifications.rb
git checkout HEAD~1 -- config/initializers/s3_storage.rb
```

2. Restore the Gemfile:
```bash
git checkout HEAD~1 -- Gemfile
```

3. Remove the plugin:
```bash
rm -rf plugins/redmine_by_smarlify
```

4. Run bundle install and restart:
```bash
bundle install
rails restart
```

## Benefits of Plugin Architecture

1. **Maintainability**: Core Redmine remains clean and easier to upgrade
2. **Modularity**: Features can be enabled/disabled by installing/removing the plugin
3. **Reusability**: Plugin can be shared across multiple Redmine instances
4. **Testing**: Plugin has its own test suite
5. **Documentation**: All documentation is self-contained within the plugin
6. **Version Control**: Plugin can be versioned independently

## Troubleshooting

### Plugin Not Loading

Check the Redmine logs:
```bash
tail -f log/production.log | grep "redmine_by_smarlify"
```

### Dependencies Not Installing

Make sure the plugin's Gemfile is being read:
```bash
bundle config list
bundle install --verbose
```

### Slack Notifications Not Working

Verify the namespace change:
```bash
rails console
RedmineBySmarlify::Services::SlackNotifier.enabled?
```

### S3 Storage Not Working

Verify the namespace change:
```bash
rails console
RedmineBySmarlify::Services::S3Storage.enabled?
```

## Support

For issues or questions:
- Check the plugin README: `plugins/redmine_by_smarlify/README.md`
- Review the CHANGELOG: `plugins/redmine_by_smarlify/CHANGELOG.md`
- Contact: https://smarlify.co
