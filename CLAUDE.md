# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup
```bash
bundle install
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/snapchat_api_spec.rb

# Alternative via Makefile
make test
```

### Linting
```bash
# Fix linting issues automatically
bundle exec standardrb --fix

# Alternative via Makefile
make lint-fix
```

### Build Tasks
```bash
# Run default task (tests + linting)
bundle exec rake

# Build gem
bundle exec rake build

# Release gem
bundle exec rake release
```

## Architecture Overview

This is a Ruby gem that provides a wrapper for the Snapchat Ads API. The codebase follows standard Ruby gem conventions with autoloading via Zeitwerk.

### Core Structure
- **Client (`lib/snapchat_api/client.rb`)**: Main API client with OAuth2 authentication, handles HTTP requests via Faraday
- **Resources (`lib/snapchat_api/resources/`)**: API endpoint wrappers following a resource-based pattern
- **Authentication (`lib/snapchat_api/auth.rb`)**: OAuth2 flow handling for Snapchat API
- **Error Handling (`lib/snapchat_api/error.rb`)**: Custom exception classes for different API error types

### Key Components
- **Base Resource Pattern**: All API resources inherit from `SnapchatApi::Resources::Base`
- **HTTP Client**: Uses Faraday with multipart support, retries, and JSON parsing
- **API Endpoints**: Organized by resource type (accounts, campaigns, campaign_items, motion_ads, operations, reportings)
- **Authentication**: OAuth2 with support for access/refresh tokens

### Dependencies
- `oauth2` for OAuth2 authentication
- `faraday` ecosystem for HTTP requests (multipart, retries, redirects)
- `zeitwerk` for autoloading
- `mime-types` for file handling
- `standard` for Ruby linting

### Testing
- Uses RSpec for testing
- VCR for recording HTTP interactions
- Standard Ruby linting with `standardrb`

### IMPORTANT NOTES

- DO NOT GENERATE DOCUMENTATION UNLESS THE USER SPECIFICALLY ASKS FOR IT!
- For commits use conventional commit messages: https://www.conventionalcommits.org/en/v1.0.0/
- DO NOT add Claude-related footers to commit messages (no "Generated with Claude Code", no "Co-Authored-By: Claude")
- DON'T USE TABS, USE SPACES FOR INDENTATION!
- DON'T WRITE ANY COMMENTS IN THE CODE THAT DESCRIBE THE CODE!!!! WRITE COMMENTS ONLY IF I ASK FOR THEM!
