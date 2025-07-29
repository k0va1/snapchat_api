RSpec.describe SnapchatApi::Resources::Ad do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:ad_resource) { client.ads }
  let(:ad_account_id) { "dbb95f66-4e45-46f0-9760-14ea841db3b4" }

  describe "#list_all_by", :vcr do
    it "handles pagination by making multiple requests" do
      ads = ad_resource.list_all_by(entity_id: ad_account_id, entity: :ad_account, params: {limit: 10})
      expect(ads).to be_an(Array)
      expect(ads.first).to include("id", "name", "status")
    end
  end

  describe "#get", :vcr do
    let(:ad_id) { "bb05b099-140f-47ad-ab96-827960fbdf16" }

    it "returns ad squad data when successful" do
      ad = ad_resource.get(ad_id: ad_id)
      expect(ad).to include("id", "name", "status") if ad
    end
  end

  describe "#create", :vcr do
    before do
      @ad_squad_id = client.ad_squads.create(
        campaign_id: "ce00d8e1-ebb1-4885-8348-cf5c20375179",
        params: {
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
      )["id"]

      @media_id = "e2412304-2bb4-4145-aea2-8498414892f8"
      @creative_id = client.creatives.create(
        ad_account_id: ad_account_id,
        params: {
          name: "Test Creative",
          type: "SNAP_AD",
          top_snap_media_id: @media_id,
          headline: "Test Headline",
          ad_account_id: ad_account_id,
          profile_properties: {
            profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
          }
        }
      )["id"]
    end
    let(:campaign_id) { "ce00d8e1-ebb1-4885-8348-cf5c20375179" }
    let(:ad_squad_id) { @ad_squad_id }
    let(:ad_params) do
      {
        name: "Ad Uno",
        ad_squad_id: ad_squad_id,
        start_time: "2025-08-11T22:03:58.869Z",
        status: "PAUSED",
        type: "SNAP_AD",
        creative_id: @creative_id

      }
    end
    @existing_ad_id = nil

    it "creates an ad" do
      ad = ad_resource.create(ad_squad_id: ad_squad_id, params: ad_params)
      @existing_ad_id = ad["id"]
      expect(ad).to include("id", "name", "status")
      expect(ad["name"]).to eq("Ad Uno")
      expect(ad["status"]).to eq("PAUSED")
    end

    after do
      if @existing_ad_id
        ad_resource.delete(ad_id: @existing_ad_id)
      end

      if @ad_squad_id
        client.ad_squads.delete(ad_squad_id: @ad_squad_id)
      end
    end
  end

  describe "#update", :vcr do
    before do
      @ad_squad_id = client.ad_squads.create(
        campaign_id: "ce00d8e1-ebb1-4885-8348-cf5c20375179",
        params: {
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
      )["id"]

      @media_id = "e2412304-2bb4-4145-aea2-8498414892f8"
      @creative_id = client.creatives.create(
        ad_account_id: ad_account_id,
        params: {
          name: "Test Creative",
          type: "SNAP_AD",
          top_snap_media_id: @media_id,
          headline: "Test Headline",
          ad_account_id: ad_account_id,
          profile_properties: {
            profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
          }
        }
      )["id"]

      @existing_ad = ad_resource.create(ad_squad_id: @ad_squad_id, params: {
        name: "Ad Uno",
        ad_squad_id: @ad_squad_id,
        start_time: "2025-08-11T22:03:58.869Z",
        status: "PAUSED",
        type: "SNAP_AD",
        creative_id: @creative_id
      })
      @existing_ad_id = @existing_ad["id"]
    end
    let(:ad_params) do
      {
        name: "Ad Uno",
        ad_squad_id: ad_squad_id,
        start_time: "2025-08-11T22:03:58.869Z",
        status: "PAUSED",
        type: "SNAP_AD",
        creative_id: @creative_id

      }
    end

    let(:update_params) do
      @existing_ad.merge(name: "Updated Ad Name", status: "PAUSED")
    end

    it "updates ad" do
      updated_ad = ad_resource.update(
        ad_squad_id: @ad_squad_id,
        params: update_params
      )
      expect(updated_ad).to include("id", "name", "status")
      expect(updated_ad["name"]).to eq("Updated Ad Name")
      expect(updated_ad["status"]).to eq("PAUSED")
    end

    after do
      if @existing_ad_id
        ad_resource.delete(ad_id: @existing_ad_id)
      end
      if @ad_squad_id
        client.ad_squads.delete(ad_squad_id: @ad_squad_id)
      end
    end
  end

  describe "#get_stats", :vcr do
    let(:ad_id) { "bb05b099-140f-47ad-ab96-827960fbdf16" }

    it "returns granular stats" do
      response = ad_resource.get_stats(
        ad_id: ad_id,
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
      response = ad_resource.get_stats(
        ad_id: ad_id,
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
end
