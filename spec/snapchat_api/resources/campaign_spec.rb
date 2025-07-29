RSpec.describe SnapchatApi::Resources::Campaign do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:campaign_resource) {client.refresh_tokens!; client.campaigns }
  let(:ad_account_id) { "dbb95f66-4e45-46f0-9760-14ea841db3b4" }

  describe "#list_all", :vcr do
    it "handles pagination by making multiple requests" do
      campaigns = campaign_resource.list_all(ad_account_id: ad_account_id)
      expect(campaigns).to be_an(Array)
      expect(campaigns.first).to include("id", "name", "status")
    end
  end

  describe "#get", :vcr do
    let(:campaign_id) { "ce00d8e1-ebb1-4885-8348-cf5c20375179" }

    it "returns campaign data when successful" do
      campaign = campaign_resource.get(ad_account_id: ad_account_id, campaign_id: campaign_id)
      expect(campaign).to include("id", "name", "status")
    end
  end

  describe "#create", :vcr do
    let(:campaign_params) do
      {
        name: "Test Campaign",
        status: "ACTIVE",
        start_time: "2026-01-01T00:00:00.000Z",
        end_time: "2026-12-31T23:59:59.999Z",
        daily_budget_micro: 20000000,
        lifetime_spend_cap_micro: 20000000
      }
    end

    @existing_campaign_id = nil

    it "creates the campaign" do
      campaign = campaign_resource.create(ad_account_id: ad_account_id, params: campaign_params)
      @existing_campaign_id = campaign["id"]
      expect(campaign).to include("id", "name", "status")
      expect(campaign["name"]).to eq("Test Campaign")
      expect(campaign["status"]).to eq("ACTIVE")
    end

    after do
      if @existing_ad_squad_id
        campaign_resource.delete(campaign_id: @existing_campaign_id)
      end
    end
  end

  describe "#update", :vcr do
    before do
      @existing_campaign = campaign_resource.create(ad_account_id: ad_account_id, params: {
        name: "Temporary Campaign",
        status: "ACTIVE",
        start_time: "2026-01-01T00:00:00.000Z",
        end_time: "2026-12-31T23:59:59.999Z",
        daily_budget_micro: 20000000,
        lifetime_spend_cap_micro: 20000000
      })
      @existing_campaign_id = @existing_campaign["id"]
    end
    let(:campaign_id) { @existing_campaign_id  }

    let(:update_params) do
      {
        name: "Updated Campaign Name",
        status: "PAUSED",
        start_time: "2027-01-01T00:00:00.000Z"
      }
    end

    it "updates campaign" do
      campaign = campaign_resource.update(
        ad_account_id: ad_account_id,
        campaign_id: campaign_id,
        params: update_params
      )
      expect(campaign).to include("id", "name", "status")
      expect(campaign["name"]).to eq("Updated Campaign Name")
    end

    after do
      if @existing_campaign_id
        campaign_resource.delete(campaign_id: @existing_campaign_id)
      end
    end
  end

  describe "#delete", :vcr do
    before do
      @existing_campaign = campaign_resource.create(ad_account_id: ad_account_id, params: {
        name: "Temporary Campaign",
        status: "ACTIVE",
        start_time: "2026-01-01T00:00:00.000Z",
        end_time: "2026-12-31T23:59:59.999Z",
        daily_budget_micro: 20000000,
        lifetime_spend_cap_micro: 20000000
      })
      @existing_campaign_id = @existing_campaign["id"]
    end

    let(:campaign_id) { @existing_campaign_id }

    it "deletes campaign" do
      result = campaign_resource.delete(campaign_id: campaign_id)
      expect(result).to be(true)
    end
  end

  describe "#get_stats", :vcr do
    let(:campaign_id) { "ce00d8e1-ebb1-4885-8348-cf5c20375179" }

    it "returns granular stats" do
      response = campaign_resource.get_stats(
        campaign_id: campaign_id,
        params: {granularity: "DAY", start_time: "2025-07-01T00:00:00+02:00", end_time: "2025-07-31T00:00:00+02:00"}
      )
      expect(response["timeseries_stats"]).to be_an(Array)
      expect(response["timeseries_stats"].first["timeseries_stat"]).to include("id", "type", "granularity", "start_time", "end_time")
    end

    it "returns total stats" do
      response = campaign_resource.get_stats(campaign_id: campaign_id, params: {granularity: "TOTAL", start_time: "2025-07-01T00:00:00+02:00", end_time: "2025-07-31T00:00:00+02:00"})
      expect(response["total_stats"]).to be_a(Array)
      expect(response["total_stats"].first["total_stat"]).to include("id", "type", "stats")
    end
  end
end
