# frozen_string_literal: true

require "test_helper"

class FundingSourceTest < SnapchatApiTestCase
  ORGANIZATION_ID = "14d6bf9e-353e-43dd-94a3-689231ca9dc0"

  def test_list_all_returns_all_funding_sources_for_an_organization
    with_cassette("_list_all/returns_all_funding_sources_for_an_organization") do
      funding_sources = funding_source_resource.list_all(organization_id: ORGANIZATION_ID)
      assert_kind_of Array, funding_sources
      assert_has_keys funding_sources.first, "id", "type"
    end
  end

  def test_list_all_accepts_custom_limit_parameter
    with_cassette("_list_all/accepts_custom_limit_parameter") do
      funding_sources = funding_source_resource.list_all(organization_id: ORGANIZATION_ID, params: {limit: 10})
      assert_kind_of Array, funding_sources
    end
  end

  def test_get_returns_a_specific_funding_source
    funding_source_id = "894d168d-9b50-4c97-86b6-929ad2397287"

    with_cassette("_get/returns_a_specific_funding_source") do
      funding_source = funding_source_resource.get(funding_source_id: funding_source_id)
      assert_has_keys funding_source, "id", "type"
      assert_equal funding_source_id, funding_source["id"]
    end
  end

  private

  def funding_source_resource
    @funding_source_resource ||= client.funding_sources
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_FundingSource/#{name}", &block)
  end
end
