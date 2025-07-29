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
client.get_authorization_url
# => "https://accounts.snapchat.com/accounts/oauth2/auth?client_id=your-client-id&redirect_uri=your-redirect-uri&response_type=code&scope=your-scope"

client.get_tokens(code: "your-authorization-code")

client.refresh_tokens!
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
