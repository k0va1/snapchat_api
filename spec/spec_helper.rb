# frozen_string_literal: true

require "snapchat_api"
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false

  config.filter_sensitive_data("<CLIENT_ID>") { ENV["SNAPCHAT_CLIENT_ID"] }
  config.filter_sensitive_data("<CLIENT_SECRET>") { ENV["SNAPCHAT_CLIENT_SECRET"] }
  config.filter_sensitive_data("<ACCESS_TOKEN>") { ENV["SNAPCHAT_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<REFRESH_TOKEN>") { ENV["SNAPCHAT_REFRESH_TOKEN"] }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
