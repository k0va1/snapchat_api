RSpec.describe SnapchatApi::Resources::Creative do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:creative_resource) { client.creatives }
  let(:ad_account_id) { "dbb95f66-4e45-46f0-9760-14ea841db3b4" }
  let(:creative_id) { "8f9d8d06-7c0e-462b-9d76-23dfea9b9bbc" }
  let(:media_id) { "e2412304-2bb4-4145-aea2-8498414892f8" }

  describe "#list_all", :vcr do
    it "handles pagination by making multiple requests" do
      creatives = creative_resource.list_all(ad_account_id: ad_account_id)
      expect(creatives).to be_an(Array)
      expect(creatives.first).to include("id", "name", "type") if creatives.any?
    end

    it "accepts custom limit parameter" do
      creatives = creative_resource.list_all(ad_account_id: ad_account_id, params: {limit: 10})
      expect(creatives).to be_an(Array)
    end
  end

  describe "#get", :vcr do
    it "returns creative data when successful" do
      creative = creative_resource.get(creative_id: creative_id)
      expect(creative).to include("id", "name", "type")
    end
  end

  describe "#create", :vcr do
    let(:creative_params) do
      {
        name: "Test Creative",
        type: "SNAP_AD",
        top_snap_media_id: media_id,
        headline: "Test Headline",
        ad_account_id: ad_account_id,
        profile_properties: {
          profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
        }
      }
    end

    it "creates creative successfully" do
      creative = creative_resource.create(
        ad_account_id: ad_account_id,
        params: creative_params
      )
      expect(creative).to include("id", "name", "type")
      expect(creative["name"]).to eq("Test Creative")
      expect(creative["type"]).to eq("SNAP_AD")
    end
  end

  describe "#update", :vcr do
    before do
      @creative = creative_resource.create(
        ad_account_id: ad_account_id,
        params: {
          name: "Test Creative",
          type: "SNAP_AD",
          top_snap_media_id: media_id,
          headline: "Test Headline",
          ad_account_id: ad_account_id,
          profile_properties: {
            profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
          }
        }
      )
      @creative_id = @creative["id"]
    end

    let(:update_params) { @creative.merge(name: "Updated Creative Name") }

    it "updates creative successfully" do
      creative = creative_resource.update(
        ad_account_id: ad_account_id,
        creative_id: @creative_id,
        params: update_params
      )
      expect(creative).to include("id", "name")
      expect(creative["name"]).to eq("Updated Creative Name")
    end
  end
end
