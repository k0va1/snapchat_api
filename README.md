# SnapchatApi

A Ruby gem that provides a comprehensive wrapper for the Snapchat Ads API, supporting OAuth2 authentication and full CRUD operations for campaigns, ad squads, ads, creatives, and media.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snapchat_api'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install snapchat_api

## Usage

### Creating a Client

```ruby
require 'snapchat_api'

client = SnapchatApi::Client.new(
  client_id: "your-client-id",
  client_secret: "your-client-secret",
  redirect_uri: "your-redirect-uri",
  access_token: "your-access-token",
  refresh_token: "your-refresh-token",
  debug: false # Optional: enable debug logging
)
```

### OAuth2 Authentication

```ruby
# Get authorization URL
auth_url = client.get_authorization_url(scope: "snapchat-marketing-api")
# => "https://accounts.snapchat.com/accounts/oauth2/auth?client_id=your-client-id&redirect_uri=your-redirect-uri&response_type=code&scope=snapchat-marketing-api"

# Exchange authorization code for tokens
tokens = client.get_tokens(code: "your-authorization-code")
# => {"access_token" => "...", "refresh_token" => "...", "expires_in" => 3600}

# Refresh access tokens
client.refresh_tokens!
```

## API Resources

### Accounts (`SnapchatApi::Resources::Account`)

Manage ad accounts within organizations.

```ruby
# List all ad accounts for an organization
accounts = client.accounts.list_all(organization_id: "org-id", params: {limit: 50})
```

### Campaigns (`SnapchatApi::Resources::Campaign`)

Full CRUD operations for campaigns.

```ruby
# List all campaigns for an ad account
campaigns = client.campaigns.list_all(ad_account_id: "account-id", params: {limit: 50})

# Get a specific campaign
campaign = client.campaigns.get(ad_account_id: "account-id", campaign_id: "campaign-id")

# Create a new campaign
new_campaign = client.campaigns.create(
  ad_account_id: "account-id",
  params: {
    name: "My Campaign",
    status: "ACTIVE",
    objective: "AWARENESS"
  }
)

# Update a campaign
updated_campaign = client.campaigns.update(
  ad_account_id: "account-id",
  campaign_id: "campaign-id",
  params: {name: "Updated Campaign Name"}
)

# Delete a campaign
client.campaigns.delete(campaign_id: "campaign-id")

# Get campaign statistics
stats = client.campaigns.get_stats(campaign_id: "campaign-id", params: {granularity: "DAY"})
```

### Ad Squads (`SnapchatApi::Resources::AdSquad`)

Manage ad squads within campaigns.

```ruby
# List all ad squads for an ad account
ad_squads = client.ad_squads.list_all(ad_account_id: "account-id", params: {limit: 50})

# Get a specific ad squad
ad_squad = client.ad_squads.get(ad_squad_id: "squad-id")

# Create a new ad squad
new_ad_squad = client.ad_squads.create(
  campaign_id: "campaign-id",
  params: {
    name: "My Ad Squad",
    status: "ACTIVE",
    type: "SNAP_ADS"
  }
)

# Update an ad squad
updated_ad_squad = client.ad_squads.update(
  campaign_id: "campaign-id",
  ad_squad_id: "squad-id",
  params: {name: "Updated Ad Squad"}
)

# Delete an ad squad
client.ad_squads.delete(ad_squad_id: "squad-id")

# Get ad squad statistics
stats = client.ad_squads.get_stats(ad_squad_id: "squad-id", params: {granularity: "DAY"})
```

### Ads (`SnapchatApi::Resources::Ad`)

Create and manage individual ads.

```ruby
# Create a new ad
new_ad = client.ads.create(
  ad_squad_id: "squad-id",
  params: {
    name: "My Ad",
    creative_id: "creative-id",
    status: "ACTIVE"
  }
)

# List ads by different entities
ads_by_squad = client.ads.list_all_by(entity_id: "squad-id", entity: :ad_squad)
ads_by_account = client.ads.list_all_by(entity_id: "account-id", entity: :ad_account)
ads_by_campaign = client.ads.list_all_by(entity_id: "campaign-id", entity: :campaign)

# Get a specific ad
ad = client.ads.get(ad_id: "ad-id")

# Update an ad
updated_ad = client.ads.update(
  ad_squad_id: "squad-id",
  params: {id: "ad-id", name: "Updated Ad Name"}
)

# Delete an ad
client.ads.delete(ad_id: "ad-id")

# Get ad statistics
stats = client.ads.get_stats(ad_id: "ad-id", params: {granularity: "DAY"})
```

### Creatives (`SnapchatApi::Resources::Creative`)

Manage creative assets for ads.

```ruby
# List all creatives for an ad account
creatives = client.creatives.list_all(ad_account_id: "account-id", params: {limit: 50})

# Get a specific creative
creative = client.creatives.get(creative_id: "creative-id")

# Create a new creative
new_creative = client.creatives.create(
  ad_account_id: "account-id",
  params: {
    name: "My Creative",
    type: "IMAGE",
    top_snap_media_id: "media-id"
  }
)

# Update a creative
updated_creative = client.creatives.update(
  ad_account_id: "account-id",
  creative_id: "creative-id",
  params: {name: "Updated Creative Name"}
)
```

### Media (`SnapchatApi::Resources::Media`)

Upload and manage media files.

```ruby
# List all media for an ad account
media_items = client.media.list_all(ad_account_id: "account-id", params: {limit: 50})

# Get a specific media item
media = client.media.get(media_id: "media-id")

# Create a new media placeholder
new_media = client.media.create(
  ad_account_id: "account-id",
  params: {
    name: "My Media",
    type: "IMAGE"
  }
)

# Upload a file to the media placeholder
result = client.media.upload(
  media_id: "media-id",
  file_path: "/path/to/image.jpg"
)
```

## Error Handling

The gem provides specific error classes for different API error scenarios:

- `SnapchatApi::AuthenticationError` (401) - Invalid or expired access token
- `SnapchatApi::AuthorizationError` (403) - Insufficient permissions
- `SnapchatApi::InvalidRequestError` (400-499) - Bad request or client error
- `SnapchatApi::RateLimitError` (429) - Rate limit exceeded
- `SnapchatApi::ApiError` (500-599) - Server error
- `SnapchatApi::Error` - Base error class

```ruby
begin
  campaigns = client.campaigns.list_all(ad_account_id: "invalid-id")
rescue SnapchatApi::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
  client.refresh_tokens! # Try refreshing tokens
rescue SnapchatApi::RateLimitError => e
  puts "Rate limit exceeded, waiting..."
  sleep(60)
  retry
rescue SnapchatApi::Error => e
  puts "API error: #{e.message} (Status: #{e.status_code})"
end
```

## Configuration

### Debug Mode

Enable debug mode to see detailed HTTP request/response logs:

```ruby
client = SnapchatApi::Client.new(
  client_id: "your-client-id",
  client_secret: "your-client-secret",
  debug: true
)
```

### Connection Settings

The client uses Faraday with the following default settings:
- Request timeout: 60 seconds
- Open timeout: 30 seconds
- Maximum retries: 3
- Multipart support for file uploads
- Automatic redirect following

## Development

```bash
make install
make test
```

To run linting and fix issues automatically:
```bash
make lint-fix
```

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.
