# SnapchatApi

## Usage

### Creating a Client

```ruby
require 'snapchat_api'

client = SnapchatApi::Client.new(
  client_id: "your-client-id",
  client_secret: "your-client-secret",
  redirect_uri: "your-redirect-uri",
  access_token: "your-access-token",
  refresh_token: "your-refresh-token"
)
```

### Authorization

```ruby
client.auth.get_authorization_url(scope: "your-scope")
# => "https://accounts.snapchat.com/accounts/oauth2/auth?client_id=your-client-id&redirect_uri=your-redirect-uri&response_type=code&scope=your-scope"

client.auth.update_tokens!(code: "your-authorization-code")

client.auth.refresh_access_token!
```

### Accounts

```ruby
# List all allowed accounts
accounts = client.accounts.list_all
puts accounts
```

### Campaigns

```ruby
# List all campaigns
campaigns = client.campaigns.list_all("account-id")
puts campaigns

# Get a specific campaign
campaign = client.campaigns.get("account-id", "campaign-id")
puts campaign
```

### Campaign Items

```ruby
# List all campaign items
campaign_items = client.campaign_items.list_all("account-id", "campaign-id")
puts campaign_items

# Get a specific campaign item
campaign_item = client.campaign_items.get("account-id", "campaign-id", "item-id")
puts campaign_item

# Create a new campaign item
new_campaign_item = client.campaign_items.create("account-id", "campaign-id", {
  name: "New Campaign Item",
  url: "https://example.com"
})
puts new_campaign_item

# Update an existing campaign item
updated_campaign_item = client.campaign_items.update("account-id", "campaign-id", "item-id", {
  name: "Updated Campaign Item"
})
puts updated_campaign_item
```

### Motion Ads

```ruby
# List all motion ads
motion_ads = client.motion_ads.list_all("account-id", "campaign-id")
puts motion_ads

# Get a specific motion ad
motion_ad = client.motion_ads.get("account-id", "campaign-id", "item-id")
puts motion_ad

# Create a new motion ad
video_file = File.open("path/to/video.mp4")
fallback_file = File.open("path/to/fallback.jpg")
new_motion_ad = client.motion_ads.create("account-id", "campaign-id", video_file: video_file, fallback_file: fallback_file, {
  name: "New Motion Ad"
})
puts new_motion_ad

# Update an existing motion ad
updated_motion_ad = client.motion_ads.update("account-id", "campaign-id", "item-id", {
  name: "Updated Motion Ad"
})
puts updated_motion_ad
```

### Operations

```ruby
# Upload an image
image_file = File.open("path/to/image.jpg")
uploaded_image = client.operations.upload_image(image_file)
puts uploaded_image
```

### Reportings

```ruby
# Get top campaign content report
report = client.reportings.top_campaign_content_report(
  account_id: "account-id",
  start_date: "2023-01-01",
  end_date: "2023-01-31"
)
puts report
```
