# frozen_string_literal: true

require "test_helper"

class CampaignTest < SnapchatApiTestCase
  AD_ACCOUNT_ID = "dbb95f66-4e45-46f0-9760-14ea841db3b4"
  CAMPAIGN_ID = "ce00d8e1-ebb1-4885-8348-cf5c20375179"

  def test_list_all_handles_pagination_by_making_multiple_requests
    with_cassette("_list_all/handles_pagination_by_making_multiple_requests") do
      campaigns = campaign_resource.list_all(ad_account_id: AD_ACCOUNT_ID)
      assert_kind_of Array, campaigns
      assert_has_keys campaigns.first, "id", "name", "status"
    end
  end

  def test_get_returns_campaign_data_when_successful
    with_cassette("_get/returns_campaign_data_when_successful") do
      campaign = campaign_resource.get(ad_account_id: AD_ACCOUNT_ID, campaign_id: CAMPAIGN_ID)
      assert_has_keys campaign, "id", "name", "status"
    end
  end

  def test_create_creates_the_campaign
    with_cassette("_create/creates_the_campaign") do
      campaign = campaign_resource.create(ad_account_id: AD_ACCOUNT_ID, params: {
        name: "Test Campaign",
        status: "ACTIVE",
        start_time: "2026-01-01T00:00:00.000Z",
        end_time: "2026-12-31T23:59:59.999Z",
        daily_budget_micro: 20000000,
        lifetime_spend_cap_micro: 20000000
      })
      assert_has_keys campaign, "id", "name", "status"
      assert_equal "Test Campaign", campaign["name"]
      assert_equal "ACTIVE", campaign["status"]
    end
  end

  def test_update_updates_campaign
    with_cassette("_update/updates_campaign") do
      campaign_id = create_campaign["id"]

      begin
        campaign = campaign_resource.update(
          ad_account_id: AD_ACCOUNT_ID,
          campaign_id: campaign_id,
          params: {
            name: "Updated Campaign Name",
            status: "PAUSED",
            start_time: "2027-01-01T00:00:00.000Z"
          }
        )
        assert_has_keys campaign, "id", "name", "status"
        assert_equal "Updated Campaign Name", campaign["name"]
      ensure
        campaign_resource.delete(campaign_id: campaign_id)
      end
    end
  end

  def test_delete_deletes_campaign
    with_cassette("_delete/deletes_campaign") do
      campaign_id = create_campaign["id"]

      result = campaign_resource.delete(campaign_id: campaign_id)
      assert_equal true, result
    end
  end

  def test_get_stats_returns_granular_stats
    with_cassette("_get_stats/returns_granular_stats") do
      response = campaign_resource.get_stats(
        campaign_id: CAMPAIGN_ID,
        params: {granularity: "DAY", start_time: "2025-07-01T00:00:00+02:00", end_time: "2025-07-31T00:00:00+02:00"}
      )
      assert_kind_of Array, response["timeseries_stats"]
      assert_has_keys response["timeseries_stats"].first["timeseries_stat"], "id", "type", "granularity", "start_time", "end_time"
    end
  end

  def test_get_stats_returns_total_stats
    with_cassette("_get_stats/returns_total_stats") do
      response = campaign_resource.get_stats(campaign_id: CAMPAIGN_ID, params: {granularity: "TOTAL", start_time: "2025-07-01T00:00:00+02:00", end_time: "2025-07-31T00:00:00+02:00"})
      assert_kind_of Array, response["total_stats"]
      assert_has_keys response["total_stats"].first["total_stat"], "id", "type", "stats"
    end
  end

  private

  def campaign_resource
    @campaign_resource ||= begin
      client.refresh_tokens!
      client.campaigns
    end
  end

  def create_campaign
    campaign_resource.create(ad_account_id: AD_ACCOUNT_ID, params: {
      name: "Temporary Campaign",
      status: "ACTIVE",
      start_time: "2026-01-01T00:00:00.000Z",
      end_time: "2026-12-31T23:59:59.999Z",
      daily_budget_micro: 20000000,
      lifetime_spend_cap_micro: 20000000
    })
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_Campaign/#{name}", &block)
  end
end
