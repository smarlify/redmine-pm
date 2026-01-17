# Changelog

All notable changes to the Redmine by Smarlify plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-17

### Added
- Initial release of Redmine by Smarlify plugin
- Slack notifications for issues, documents, and wiki pages
- User mentions/tagging in Slack notifications
- S3 file storage support for AWS S3 and S3-compatible services
- Automatic file upload to S3 on attachment
- On-demand file download from S3
- Presigned URLs for secure file access
- Configuration via environment variables or configuration.yml
- Comprehensive test suite
- Detailed documentation

### Features

#### Slack Notifications
- Rich formatted messages with all relevant details
- Support for issue creation, updates, and comments
- Document and wiki page notifications
- User mentions based on Redmine usernames
- Direct links to Redmine items
- Test notification command

#### S3 File Storage
- Automatic upload to S3 on file attachment
- On-demand download from S3 when accessing files
- Support for AWS S3, DigitalOcean Spaces, and other S3-compatible services
- Optional local file deletion after upload (saves space on Heroku)
- Presigned URLs for secure file access
- Migration support for existing local files

### Technical Details
- Patches Redmine's Mailer class for Slack notifications
- Patches Redmine's Attachment model for S3 storage
- Uses HTTParty for Slack webhook calls
- Uses fog-aws for S3 operations
- Compatible with Redmine 6.1+ and Rails 8.0+
- Ruby 3.2+ required

### Documentation
- Comprehensive README with installation and configuration instructions
- Test suite for core functionality
- Integration guides for Heroku deployment
