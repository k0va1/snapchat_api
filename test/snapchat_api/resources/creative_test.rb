# frozen_string_literal: true

require "test_helper"

class CreativeTest < SnapchatApiTestCase
  AD_ACCOUNT_ID = "dbb95f66-4e45-46f0-9760-14ea841db3b4"
  CREATIVE_ID = "8f9d8d06-7c0e-462b-9d76-23dfea9b9bbc"
  MEDIA_ID = "e2412304-2bb4-4145-aea2-8498414892f8"

  def test_list_all_handles_pagination_by_making_multiple_requests
    with_cassette("_list_all/handles_pagination_by_making_multiple_requests") do
      creatives = creative_resource.list_all(ad_account_id: AD_ACCOUNT_ID)
      assert_kind_of Array, creatives
      assert_has_keys creatives.first, "id", "name", "type" if creatives.any?
    end
  end

  def test_list_all_accepts_custom_limit_parameter
    with_cassette("_list_all/accepts_custom_limit_parameter") do
      creatives = creative_resource.list_all(ad_account_id: AD_ACCOUNT_ID, params: {limit: 10})
      assert_kind_of Array, creatives
    end
  end

  def test_get_returns_creative_data_when_successful
    with_cassette("_get/returns_creative_data_when_successful") do
      creative = creative_resource.get(creative_id: CREATIVE_ID)
      assert_has_keys creative, "id", "name", "type"
    end
  end

  def test_create_creates_creative_successfully
    with_cassette("_create/creates_creative_successfully") do
      creative = creative_resource.create(
        ad_account_id: AD_ACCOUNT_ID,
        params: creative_params
      )
      assert_has_keys creative, "id", "name", "type"
      assert_equal "Test Creative", creative["name"]
      assert_equal "SNAP_AD", creative["type"]
    end
  end

  def test_update_updates_creative_successfully
    with_cassette("_update/updates_creative_successfully") do
      existing_creative = creative_resource.create(
        ad_account_id: AD_ACCOUNT_ID,
        params: creative_params
      )

      creative = creative_resource.update(
        ad_account_id: AD_ACCOUNT_ID,
        creative_id: existing_creative["id"],
        params: existing_creative.merge(name: "Updated Creative Name")
      )
      assert_has_keys creative, "id", "name"
      assert_equal "Updated Creative Name", creative["name"]
    end
  end

  private

  def creative_resource
    @creative_resource ||= client.creatives
  end

  def creative_params
    {
      name: "Test Creative",
      type: "SNAP_AD",
      top_snap_media_id: MEDIA_ID,
      headline: "Test Headline",
      ad_account_id: AD_ACCOUNT_ID,
      profile_properties: {
        profile_id: "c9ba7b74-06a2-4ea2-8c05-355287355971"
      }
    }
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_Creative/#{name}", &block)
  end
end
