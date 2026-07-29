# frozen_string_literal: true

require "test_helper"

class AdTest < SnapchatApiTestCase
  AD_ACCOUNT_ID = "dbb95f66-4e45-46f0-9760-14ea841db3b4"
  CAMPAIGN_ID = "ce00d8e1-ebb1-4885-8348-cf5c20375179"
  AD_ID = "bb05b099-140f-47ad-ab96-827960fbdf16"
  MEDIA_ID = "e2412304-2bb4-4145-aea2-8498414892f8"

  def test_list_all_by_handles_pagination_by_making_multiple_requests
    with_cassette("_list_all_by/handles_pagination_by_making_multiple_requests") do
      ads = ad_resource.list_all_by(entity_id: AD_ACCOUNT_ID, entity: :ad_account, params: {limit: 10})
      assert_kind_of Array, ads
      assert_has_keys ads.first, "id", "name", "status"
    end
  end

  def test_get_returns_ad_data_when_successful
    with_cassette("_get/returns_ad_squad_data_when_successful") do
      ad = ad_resource.get(ad_id: AD_ID)
      assert_has_keys ad, "id", "name", "status" if ad
    end
  end

  def test_create_creates_an_ad
    with_cassette("_create/creates_an_ad") do
      ad_squad_id = create_ad_squad["id"]
      creative_id = create_creative["id"]
      ad = nil

      begin
        ad = ad_resource.create(ad_squad_id: ad_squad_id, params: {
          name: "Ad Uno",
          ad_squad_id: ad_squad_id,
          start_time: "2025-08-11T22:03:58.869Z",
          status: "PAUSED",
          type: "SNAP_AD",
          creative_id: creative_id
        })
        assert_has_keys ad, "id", "name", "status"
        assert_equal "Ad Uno", ad["name"]
        assert_equal "PAUSED", ad["status"]
      ensure
        ad_resource.delete(ad_id: ad["id"]) if ad
        client.ad_squads.delete(ad_squad_id: ad_squad_id)
      end
    end
  end

  def test_update_updates_ad
    with_cassette("_update/updates_ad") do
      ad_squad_id = create_ad_squad["id"]
      creative_id = create_creative["id"]
      existing_ad = ad_resource.create(ad_squad_id: ad_squad_id, params: {
        name: "Ad Uno",
        ad_squad_id: ad_squad_id,
        start_time: "2025-08-11T22:03:58.869Z",
        status: "PAUSED",
        type: "SNAP_AD",
        creative_id: creative_id
      })

      begin
        updated_ad = ad_resource.update(
          ad_squad_id: ad_squad_id,
          params: existing_ad.merge(name: "Updated Ad Name", status: "PAUSED")
        )
        assert_has_keys updated_ad, "id", "name", "status"
        assert_equal "Updated Ad Name", updated_ad["name"]
        assert_equal "PAUSED", updated_ad["status"]
      ensure
        ad_resource.delete(ad_id: existing_ad["id"])
        client.ad_squads.delete(ad_squad_id: ad_squad_id)
      end
    end
  end

  def test_get_stats_returns_granular_stats
    with_cassette("_get_stats/returns_granular_stats") do
      response = ad_resource.get_stats(
        ad_id: AD_ID,
        params: {
          granularity: "DAY",
          start_time: "2025-07-01T00:00:00+02:00",
          end_time: "2025-07-31T00:00:00+02:00"
        }
      )
      assert_kind_of Hash, response
      if response["timeseries_stats"]
        assert_kind_of Array, response["timeseries_stats"]
      end
    end
  end

  def test_get_stats_returns_total_stats
    with_cassette("_get_stats/returns_total_stats") do
      response = ad_resource.get_stats(
        ad_id: AD_ID,
        params: {
          granularity: "TOTAL",
          start_time: "2025-07-01T00:00:00+02:00",
          end_time: "2025-07-31T00:00:00+02:00"
        }
      )
      assert_kind_of Hash, response
      if response["total_stats"]
        assert_kind_of Array, response["total_stats"]
      end
    end
  end

  private

  def ad_resource
    @ad_resource ||= client.ads
  end

  def create_ad_squad
    client.ad_squads.create(
      campaign_id: CAMPAIGN_ID,
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
    )
  end

  def create_creative
    client.creatives.create(
      ad_account_id: AD_ACCOUNT_ID,
      params: {
        name: "Test Creative",
        type: "SNAP_AD",
        top_snap_media_id: MEDIA_ID,
        headline: "Test Headline",
        ad_account_id: AD_ACCOUNT_ID,
        profile_properties: {
          profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
        }
      }
    )
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_Ad/#{name}", &block)
  end
end
