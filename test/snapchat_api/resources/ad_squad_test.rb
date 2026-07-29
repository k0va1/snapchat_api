# frozen_string_literal: true

require "test_helper"

class AdSquadTest < SnapchatApiTestCase
  AD_ACCOUNT_ID = "dbb95f66-4e45-46f0-9760-14ea841db3b4"
  CAMPAIGN_ID = "ce00d8e1-ebb1-4885-8348-cf5c20375179"
  AD_SQUAD_ID = "0853af89-5929-4c6d-ac6f-78310b434aac"

  def test_list_all_handles_pagination_by_making_multiple_requests
    with_cassette("_list_all/handles_pagination_by_making_multiple_requests") do
      ad_squads = ad_squad_resource.list_all(ad_account_id: AD_ACCOUNT_ID)
      assert_kind_of Array, ad_squads
      if ad_squads.any?
        assert_has_keys ad_squads.first, "id", "name", "status"
      end
    end
  end

  def test_list_all_accepts_custom_limit_parameter
    with_cassette("_list_all/accepts_custom_limit_parameter") do
      ad_squads = ad_squad_resource.list_all(ad_account_id: AD_ACCOUNT_ID, params: {limit: 10})
      assert_kind_of Array, ad_squads
    end
  end

  def test_list_all_by_campaign_returns_ad_squads_for_a_campaign
    campaign_id = "861cd1bc-5d58-44f3-8794-4006796db177"

    with_cassette("_list_all_by_campaign/returns_ad_squads_for_a_campaign") do
      ad_squads = ad_squad_resource.list_all_by_campaign(campaign_id: campaign_id)
      assert_kind_of Array, ad_squads
      assert_has_keys ad_squads.first, "id", "name", "status"
      ad_squads.each do |ad_squad|
        assert_equal campaign_id, ad_squad["campaign_id"]
      end
    end
  end

  def test_list_all_by_campaign_accepts_custom_limit_parameter
    with_cassette("_list_all_by_campaign/accepts_custom_limit_parameter") do
      ad_squads = ad_squad_resource.list_all_by_campaign(campaign_id: "861cd1bc-5d58-44f3-8794-4006796db177", params: {limit: 10})
      assert_kind_of Array, ad_squads
    end
  end

  def test_get_returns_ad_squad_data_when_successful
    with_cassette("_get/returns_ad_squad_data_when_successful") do
      ad_squad = ad_squad_resource.get(ad_squad_id: AD_SQUAD_ID)
      assert_has_keys ad_squad, "id", "name", "status" if ad_squad
    end
  end

  def test_create_creates_the_ad_squad
    with_cassette("_create/creates_the_ad_squad") do
      ad_squad = ad_squad_resource.create(campaign_id: CAMPAIGN_ID, params: ad_squad_params(name: "Ad Squad Uno"))

      begin
        assert_has_keys ad_squad, "id", "name", "status"
        assert_equal "Ad Squad Uno", ad_squad["name"]
        assert_equal "PAUSED", ad_squad["status"]
        assert_equal "SNAP_ADS", ad_squad["type"]
      ensure
        ad_squad_resource.delete(ad_squad_id: ad_squad["id"])
      end
    end
  end

  def test_update_updates_ad_squad
    with_cassette("_update/updates_ad_squad") do
      existing_ad_squad = create_ad_squad

      begin
        updated_ad_squad = ad_squad_resource.update(
          campaign_id: CAMPAIGN_ID,
          ad_squad_id: existing_ad_squad["id"],
          params: existing_ad_squad.merge(name: "Updated Ad Squad Name", status: "PAUSED")
        )
        assert_has_keys updated_ad_squad, "id", "name", "status"
        assert_equal "Updated Ad Squad Name", updated_ad_squad["name"]
        assert_equal "PAUSED", updated_ad_squad["status"]
      ensure
        ad_squad_resource.delete(ad_squad_id: existing_ad_squad["id"])
      end
    end
  end

  def test_delete_deletes_ad_squad
    with_cassette("_delete/deletes_ad_squad") do
      ad_squad_id = create_ad_squad["id"]

      result = ad_squad_resource.delete(ad_squad_id: ad_squad_id)
      assert_equal true, result
    end
  end

  def test_get_stats_returns_granular_stats
    with_cassette("_get_stats/returns_granular_stats") do
      response = ad_squad_resource.get_stats(
        ad_squad_id: AD_SQUAD_ID,
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
      response = ad_squad_resource.get_stats(
        ad_squad_id: AD_SQUAD_ID,
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

  def ad_squad_resource
    @ad_squad_resource ||= SnapchatApi::Resources::AdSquad.new(client)
  end

  def create_ad_squad
    ad_squad_resource.create(campaign_id: CAMPAIGN_ID, params: ad_squad_params(name: "Ad Squad Uno #{Time.now.to_i}"))
  end

  def ad_squad_params(name:)
    {
      name: name,
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

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_AdSquad/#{name}", &block)
  end
end
