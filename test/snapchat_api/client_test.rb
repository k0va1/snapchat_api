# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    @client = SnapchatApi::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token"
    )
  end

  def test_raises_request_error_with_sub_request_error_details
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 200,
        body: {
          "request_status" => "ERROR",
          "request_id" => "c49dc1ce-ab91-481c-80e7-f5fa65e4f1ab",
          "creatives" => [
            {
              "sub_request_error_reason" => "Error code: E2002, message: Property value is not allowed : [Top snap media aspect ratio must be 9 : 16]",
              "sub_request_status" => "ERROR"
            }
          ]
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    error = assert_raises(SnapchatApi::RequestError) { @client.request(:get, "test") }
    assert_includes error.message, "E2002"
    assert_includes error.message, "aspect ratio must be 9 : 16"
    assert_equal "c49dc1ce-ab91-481c-80e7-f5fa65e4f1ab", error.request_id
    assert_equal 200, error.status_code
    assert_kind_of Array, error.sub_errors
    assert_includes error.sub_errors.first[:reason], "E2002"
  end

  def test_raises_request_error_with_all_sub_request_errors
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 200,
        body: {
          "request_status" => "ERROR",
          "request_id" => "test-request-id",
          "ads" => [
            {
              "sub_request_error_reason" => "First error message",
              "sub_request_status" => "ERROR"
            },
            {
              "sub_request_error_reason" => "Second error message",
              "sub_request_status" => "ERROR"
            }
          ]
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    error = assert_raises(SnapchatApi::RequestError) { @client.request(:get, "test") }
    assert_includes error.message, "First error message"
    assert_includes error.message, "Second error message"
    assert_equal 2, error.sub_errors.length
  end

  def test_raises_request_error_with_debug_message
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 200,
        body: {
          "request_status" => "ERROR",
          "request_id" => "test-request-id",
          "debug_message" => "Something went wrong"
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    error = assert_raises(SnapchatApi::RequestError) { @client.request(:get, "test") }
    assert_equal "Something went wrong", error.message
    assert_empty error.sub_errors
  end

  def test_returns_the_response_without_raising_on_success
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 200,
        body: {
          "request_status" => "SUCCESS",
          "request_id" => "test-request-id",
          "creatives" => [{"id" => "123", "name" => "Test"}]
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    response = @client.request(:get, "test")
    assert_equal 200, response.status
    assert_equal "SUCCESS", response.body["request_status"]
  end

  def test_raises_authentication_error_on_401
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 401,
        body: {"message" => "Unauthorized"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    assert_raises(SnapchatApi::AuthenticationError) { @client.request(:get, "test") }
  end

  def test_raises_rate_limit_error_on_429
    stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .to_return(
        status: 429,
        body: {"message" => "Rate limited"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    assert_raises(SnapchatApi::RateLimitError) { @client.request(:get, "test") }
  end

  def test_sends_the_current_access_token_on_every_request
    stub = stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .with(headers: {"Authorization" => "Bearer test_access_token"})
      .to_return(status: 200, body: {"request_status" => "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})

    @client.request(:get, "test")

    assert_requested(stub)
  end

  def test_uses_the_new_token_after_the_access_token_is_refreshed_on_the_same_client
    first = stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .with(headers: {"Authorization" => "Bearer test_access_token"})
      .to_return(status: 401, body: {"message" => "unauthorized"}.to_json, headers: {"Content-Type" => "application/json"})

    assert_raises(SnapchatApi::AuthenticationError) { @client.request(:get, "test") }

    @client.access_token = "refreshed_access_token"
    second = stub_request(:get, "https://adsapi.snapchat.com/v1/test")
      .with(headers: {"Authorization" => "Bearer refreshed_access_token"})
      .to_return(status: 200, body: {"request_status" => "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})

    response = @client.request(:get, "test")

    assert_equal 200, response.status
    assert_requested(first)
    assert_requested(second)
  end
end
