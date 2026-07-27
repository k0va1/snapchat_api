require "tempfile"

RSpec.describe SnapchatApi::Resources::Media do
  let(:client) do
    SnapchatApi::Client.new(
      client_id: ENV["SNAPCHAT_CLIENT_ID"],
      client_secret: ENV["SNAPCHAT_CLIENT_SECRET"],
      access_token: ENV["SNAPCHAT_ACCESS_TOKEN"],
      refresh_token: ENV["SNAPCHAT_REFRESH_TOKEN"],
      debug: true
    )
  end

  let(:media_resource) { client.media }
  let(:ad_account_id) { "dbb95f66-4e45-46f0-9760-14ea841db3b4" }
  let(:media_id) { "1b2f87e1-25c0-4bd2-8879-b834704f8eb0" }

  describe "#list_all", :vcr do
    it "handles pagination by making multiple requests" do
      media_items = media_resource.list_all(ad_account_id: ad_account_id)
      expect(media_items).to be_an(Array)
      expect(media_items.first).to include("id", "name", "type") if media_items.any?
    end

    it "accepts custom limit parameter" do
      media_items = media_resource.list_all(ad_account_id: ad_account_id, params: {limit: 10})
      expect(media_items).to be_an(Array)
    end
  end

  describe "#get", :vcr do
    it "returns media data when successful" do
      media = media_resource.get(media_id: media_id)
      expect(media).to include("id", "name", "type")
    end
  end

  describe "#create", :vcr do
    let(:media_params) do
      {
        name: "Test Media",
        type: "IMAGE"
      }
    end

    it "creates media successfully" do
      media = media_resource.create(
        ad_account_id: ad_account_id,
        params: media_params
      )
      expect(media).to include("id", "name", "type")
      expect(media["name"]).to eq("Test Media")
      expect(media["type"]).to eq("IMAGE")
    end
  end

  describe "#upload_chunked" do
    let(:media_file) do
      file = Tempfile.new(["chunked_video", ".mp4"])
      file.binmode
      file.write("a" * 20)
      file.rewind
      file
    end

    let(:init_response) do
      {
        request_status: "SUCCESS",
        upload_id: "upload-123",
        add_path: "/us/v1/media/#{media_id}/multipart-upload-v2?action=ADD",
        finalize_path: "/us/v1/media/#{media_id}/multipart-upload-v2?action=FINALIZE"
      }
    end

    let(:finalize_response) do
      {
        request_status: "SUCCESS",
        result: {
          "id" => media_id,
          "name" => "Chunked Video",
          "type" => "VIDEO",
          "media_status" => "PENDING_UPLOAD"
        }
      }
    end

    before do
      stub_const("SnapchatApi::Resources::Media::CHUNKED_UPLOAD_THRESHOLD", 10)
      stub_const("SnapchatApi::Resources::Media::CHUNK_SIZE", 8)
    end

    after { media_file.close! }

    it "uploads the file in parts via multipart-upload-v2" do
      init_stub = stub_request(:post, "https://adsapi.snapchat.com/v1/media/#{media_id}/multipart-upload-v2?action=INIT")
        .to_return(status: 200, body: init_response.to_json, headers: {"Content-Type" => "application/json"})
      add_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{media_id}/multipart-upload-v2?action=ADD")
        .to_return(status: 200, body: {request_status: "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})
      finalize_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{media_id}/multipart-upload-v2?action=FINALIZE")
        .to_return(status: 200, body: finalize_response.to_json, headers: {"Content-Type" => "application/json"})

      result = media_resource.upload_chunked(media_id: media_id, file_path: media_file.path)

      expect(result["id"]).to eq(media_id)
      expect(result["media_status"]).to eq("PENDING_UPLOAD")
      expect(init_stub).to have_been_requested
      expect(add_stub).to have_been_requested.times(3)
      expect(finalize_stub).to have_been_requested
    end

    it "is used automatically by #upload when the file exceeds the threshold" do
      stub_request(:post, "https://adsapi.snapchat.com/v1/media/#{media_id}/multipart-upload-v2?action=INIT")
        .to_return(status: 200, body: init_response.to_json, headers: {"Content-Type" => "application/json"})
      add_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{media_id}/multipart-upload-v2?action=ADD")
        .to_return(status: 200, body: {request_status: "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})
      stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{media_id}/multipart-upload-v2?action=FINALIZE")
        .to_return(status: 200, body: finalize_response.to_json, headers: {"Content-Type" => "application/json"})

      result = media_resource.upload(media_id: media_id, file_path: media_file.path)

      expect(result["id"]).to eq(media_id)
      expect(add_stub).to have_been_requested.times(3)
    end
  end

  describe "#upload", :vcr do
    let(:test_image_path) { File.join(__dir__, "../../fixtures/test_image.png") }

    it "uploads media file to existing media record" do
      media = media_resource.create(
        ad_account_id: ad_account_id,
        params: {
          name: "Test Upload Media",
          type: "IMAGE"
        }
      )

      uploaded_media = media_resource.upload(
        media_id: media["id"],
        file_path: test_image_path
      )
      expect(uploaded_media).to include("id", "name", "type")
      expect(uploaded_media["id"]).to eq(media["id"])
    end
  end
end
