# frozen_string_literal: true

require "test_helper"

class OrganizationTest < SnapchatApiTestCase
  def test_list_all_returns_all_organizations
    with_cassette("_list_all/returns_all_organizations") do
      organizations = organization_resource.list_all
      assert_kind_of Array, organizations
      assert_has_keys organizations.first, "id", "name"
    end
  end

  def test_list_all_returns_organizations_with_ad_accounts_when_requested
    with_cassette("_list_all/returns_organizations_with_ad_accounts_when_requested") do
      organizations = organization_resource.list_all(params: {with_ad_accounts: true})
      assert_kind_of Array, organizations
      assert_has_keys organizations.first, "id", "name", "locality"
    end
  end

  def test_get_returns_a_specific_organization
    with_cassette("_get/returns_a_specific_organization") do
      organization_id = organization_resource.list_all.first["id"]

      organization = organization_resource.get(organization_id: organization_id)
      assert_has_keys organization, "id", "name"
      assert_equal organization_id, organization["id"]
    end
  end

  private

  def organization_resource
    @organization_resource ||= client.organizations
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_Organization/#{name}", &block)
  end
end
