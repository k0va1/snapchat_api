RSpec.describe SnapchatApi::Resources::AdSquad do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:ad_squad_resource) { described_class.new(client) }
  let(:ad_account_id) { "dbb95f66-4e45-46f0-9760-14ea841db3b4" }
  let(:campaign_id) { "ce00d8e1-ebb1-4885-8348-cf5c20375179" }

  describe "#list_all", :vcr do
    it "handles pagination by making multiple requests" do
      ad_squads = ad_squad_resource.list_all(ad_account_id: ad_account_id)
      expect(ad_squads).to be_an(Array)
      if ad_squads.any?
        expect(ad_squads.first).to include("id", "name", "status")
      end
    end

    it "accepts custom limit parameter" do
      ad_squads = ad_squad_resource.list_all(ad_account_id: ad_account_id, params: {limit: 10})
      expect(ad_squads).to be_an(Array)
    end
  end

  describe "#get", :vcr do
    let(:ad_squad_id) { "0853af89-5929-4c6d-ac6f-78310b434aac" }

    it "returns ad squad data when successful" do
      ad_squad = ad_squad_resource.get(ad_squad_id: ad_squad_id)
      expect(ad_squad).to include("id", "name", "status") if ad_squad
    end
    end

  describe "#create", :vcr do
    let(:ad_squad_params) do
      {
        name: "Ad Squad Uno",
        type: "SNAP_ADS",
        placement_v2: {
          config: "AUTOMATIC"
        },
        optimization_goal: "IMPRESSIONS",
        bid_micro: 100000,
        daily_budget_micro: 1000000,
        bid_strategy: "LOWEST_COST_WITH_MAX_BID",
        billing_event: "IMPRESSION",
        targeting: {
          geos: [
            {
              country_code: "us"
            }
          ]
        },
        start_time: "2025-08-11T22:03:58.869Z"
      }
    end
    @existing_ad_squad_id = nil

    it "creates the ad squad" do
      ad_squad = ad_squad_resource.create(campaign_id: campaign_id, params: ad_squad_params)
      @existing_ad_squad_id = ad_squad["id"]
      expect(ad_squad).to include("id", "name", "status")
      expect(ad_squad["name"]).to eq("Ad Squad Uno")
      expect(ad_squad["status"]).to eq("PAUSED")
      expect(ad_squad["type"]).to eq("SNAP_ADS")
    end

    after do
      if @existing_ad_squad_id
        ad_squad_resource.delete(ad_squad_id: @existing_ad_squad_id)
      end
    end
  end

  describe "#update", :vcr do
    before do
      @existing_ad_squad = create_ad_squad
      @existing_ad_squad_id = @existing_ad_squad["id"]
    end

    let(:update_params) do
      @existing_ad_squad.merge(name: "Updated Ad Squad Name", status: "PAUSED")
    end

    it "updates ad squad" do
      updated_ad_squad = ad_squad_resource.update(
        campaign_id: campaign_id,
        ad_squad_id: @existing_ad_squad_id,
        params: update_params
      )
      expect(updated_ad_squad).to include("id", "name", "status")
      expect(updated_ad_squad["name"]).to eq("Updated Ad Squad Name")
      expect(updated_ad_squad["status"]).to eq("PAUSED")
    end

    after do
      if @existing_ad_squad_id
        ad_squad_resource.delete(ad_squad_id: @existing_ad_squad_id)
      end
    end
  end

  describe "#delete", :vcr do
    before do
      @existing_ad_squad_id = create_ad_squad["id"]
    end

    it "deletes ad squad" do
      result = ad_squad_resource.delete(ad_squad_id: @existing_ad_squad_id)
      expect(result).to eq(true)
    end
  end

  describe "#get_stats", :vcr do
    let(:ad_squad_id) { "0853af89-5929-4c6d-ac6f-78310b434aac" }

    it "returns granular stats" do
      response = ad_squad_resource.get_stats(
        ad_squad_id: ad_squad_id,
        params: {
          granularity: "DAY",
          start_time: "2025-07-01T00:00:00+02:00",
          end_time: "2025-07-31T00:00:00+02:00"
        }
      )
      expect(response).to be_a(Hash)
      if response["timeseries_stats"]
        expect(response["timeseries_stats"]).to be_an(Array)
      end
    end

    it "returns total stats" do
      response = ad_squad_resource.get_stats(
        ad_squad_id: ad_squad_id,
        params: {
          granularity: "TOTAL",
          start_time: "2025-07-01T00:00:00+02:00",
          end_time: "2025-07-31T00:00:00+02:00"
        }
      )
      expect(response).to be_a(Hash)
      if response["total_stats"]
        expect(response["total_stats"]).to be_an(Array)
      end
    end
  end

  def create_ad_squad
    ad_squad_resource.create(campaign_id: campaign_id, params: {
      name: "Ad Squad Uno #{Time.now.to_i}",
      type: "SNAP_ADS",
      placement_v2: {
        config: "AUTOMATIC"
      },
      optimization_goal: "IMPRESSIONS",
      bid_micro: 100000,
      daily_budget_micro: 1000000,
      bid_strategy: "LOWEST_COST_WITH_MAX_BID",
      billing_event: "IMPRESSION",
      targeting: {
        geos: [
          {
            country_code: "us"
          }
        ]
      },
      start_time: "2025-08-11T22:03:58.869Z"
    })
  end
end
