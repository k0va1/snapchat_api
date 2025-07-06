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
