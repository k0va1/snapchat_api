RSpec.describe SnapchatApi::Resources::Organization do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:organization_resource) { client.organizations }

  describe "#list_all", :vcr do
    it "returns all organizations" do
      organizations = organization_resource.list_all
      expect(organizations).to be_an(Array)
      expect(organizations.first).to include("id", "name")
    end

    it "returns organizations with ad accounts when requested" do
      organizations = organization_resource.list_all(params: {with_ad_accounts: true})
      expect(organizations).to be_an(Array)
      expect(organizations.first).to include("id", "name", "locality")
    end
  end

  describe "#get", :vcr do
    let(:organization_id) { organization_resource.list_all.first["id"] }

    it "returns a specific organization" do
      organization = organization_resource.get(organization_id: organization_id)
      expect(organization).to include("id", "name")
      expect(organization["id"]).to eq(organization_id)
    end
  end
end
