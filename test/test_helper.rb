# frozen_string_literal: true

require "snapchat_api"
require "minitest/autorun"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = false

  config.filter_sensitive_data("<CLIENT_ID>") { ENV["SNAPCHAT_CLIENT_ID"] }
  config.filter_sensitive_data("<CLIENT_SECRET>") { ENV["SNAPCHAT_CLIENT_SECRET"] }
  config.filter_sensitive_data("<ACCESS_TOKEN>") { ENV["SNAPCHAT_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<REFRESH_TOKEN>") { ENV["SNAPCHAT_REFRESH_TOKEN"] }
end

class SnapchatApiTestCase < Minitest::Test
  private

  def client
    @client ||= SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  def assert_has_keys(hash, *keys)
    keys.each { |key| assert_includes hash.keys, key }
  end
end
