# frozen_string_literal: true

RSpec.describe SnapchatApi::Client do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token"
    )
  end

  describe "#handle_response" do
    context "when request_status is ERROR with sub-request errors" do
      before do
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
      end

      it "raises RequestError with sub-request error details" do
        expect { client.request(:get, "test") }.to raise_error(SnapchatApi::RequestError) do |error|
          expect(error.message).to include("E2002")
          expect(error.message).to include("aspect ratio must be 9 : 16")
          expect(error.request_id).to eq("c49dc1ce-ab91-481c-80e7-f5fa65e4f1ab")
          expect(error.status_code).to eq(200)
          expect(error.sub_errors).to be_an(Array)
          expect(error.sub_errors.first[:reason]).to include("E2002")
        end
      end
    end

    context "when request_status is ERROR with multiple sub-request errors" do
      before do
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
      end

      it "raises RequestError with all sub-request errors" do
        expect { client.request(:get, "test") }.to raise_error(SnapchatApi::RequestError) do |error|
          expect(error.message).to include("First error message")
          expect(error.message).to include("Second error message")
          expect(error.sub_errors.length).to eq(2)
        end
      end
    end

    context "when request_status is ERROR without sub-request errors" do
      before do
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
      end

      it "raises RequestError with debug message" do
        expect { client.request(:get, "test") }.to raise_error(SnapchatApi::RequestError) do |error|
          expect(error.message).to eq("Something went wrong")
          expect(error.sub_errors).to be_empty
        end
      end
    end

    context "when request_status is SUCCESS" do
      before do
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
      end

      it "returns the response without raising" do
        response = client.request(:get, "test")
        expect(response.status).to eq(200)
        expect(response.body["request_status"]).to eq("SUCCESS")
      end
    end

    context "when HTTP status is 401" do
      before do
        stub_request(:get, "https://adsapi.snapchat.com/v1/test")
          .to_return(
            status: 401,
            body: {"message" => "Unauthorized"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "raises AuthenticationError" do
        expect { client.request(:get, "test") }.to raise_error(SnapchatApi::AuthenticationError)
      end
    end

    context "when HTTP status is 429" do
      before do
        stub_request(:get, "https://adsapi.snapchat.com/v1/test")
          .to_return(
            status: 429,
            body: {"message" => "Rate limited"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "raises RateLimitError" do
        expect { client.request(:get, "test") }.to raise_error(SnapchatApi::RateLimitError)
      end
    end
  end
end
