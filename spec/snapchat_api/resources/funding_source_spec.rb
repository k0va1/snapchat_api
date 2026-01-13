RSpec.describe SnapchatApi::Resources::FundingSource do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:funding_source_resource) { client.funding_sources }
  let(:organization_id) { "14d6bf9e-353e-43dd-94a3-689231ca9dc0" }

  describe "#list_all", :vcr do
    it "returns all funding sources for an organization" do
      funding_sources = funding_source_resource.list_all(organization_id: organization_id)
      expect(funding_sources).to be_an(Array)
      expect(funding_sources.first).to include("id", "type")
    end

    it "accepts custom limit parameter" do
      funding_sources = funding_source_resource.list_all(organization_id: organization_id, params: {limit: 10})
      expect(funding_sources).to be_an(Array)
    end
  end

  describe "#get", :vcr do
    let(:funding_source_id) { "894d168d-9b50-4c97-86b6-929ad2397287" }

    it "returns a specific funding source" do
      funding_source = funding_source_resource.get(funding_source_id: funding_source_id)
      expect(funding_source).to include("id", "type")
      expect(funding_source["id"]).to eq(funding_source_id)
    end
  end
end
