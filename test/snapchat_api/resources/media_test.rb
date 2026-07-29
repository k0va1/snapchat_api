# frozen_string_literal: true

require "test_helper"
require "tempfile"

class MediaTest < SnapchatApiTestCase
  AD_ACCOUNT_ID = "dbb95f66-4e45-46f0-9760-14ea841db3b4"
  MEDIA_ID = "1b2f87e1-25c0-4bd2-8879-b834704f8eb0"

  def teardown
    @chunked_media_file&.close!
    super
  end

  def test_list_all_handles_pagination_by_making_multiple_requests
    with_cassette("_list_all/handles_pagination_by_making_multiple_requests") do
      media_items = media_resource.list_all(ad_account_id: AD_ACCOUNT_ID)
      assert_kind_of Array, media_items
      assert_has_keys media_items.first, "id", "name", "type" if media_items.any?
    end
  end

  def test_list_all_accepts_custom_limit_parameter
    with_cassette("_list_all/accepts_custom_limit_parameter") do
      media_items = media_resource.list_all(ad_account_id: AD_ACCOUNT_ID, params: {limit: 10})
      assert_kind_of Array, media_items
    end
  end

  def test_get_returns_media_data_when_successful
    with_cassette("_get/returns_media_data_when_successful") do
      media = media_resource.get(media_id: MEDIA_ID)
      assert_has_keys media, "id", "name", "type"
    end
  end

  def test_create_creates_media_successfully
    with_cassette("_create/creates_media_successfully") do
      media = media_resource.create(
        ad_account_id: AD_ACCOUNT_ID,
        params: {
          name: "Test Media",
          type: "IMAGE"
        }
      )
      assert_has_keys media, "id", "name", "type"
      assert_equal "Test Media", media["name"]
      assert_equal "IMAGE", media["type"]
    end
  end

  def test_upload_chunked_uploads_the_file_in_parts_via_multipart_upload_v2
    stub_consts(SnapchatApi::Resources::Media, CHUNKED_UPLOAD_THRESHOLD: 10, CHUNK_SIZE: 8) do
      init_stub = stub_request(:post, "https://adsapi.snapchat.com/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=INIT")
        .to_return(status: 200, body: init_response.to_json, headers: {"Content-Type" => "application/json"})
      add_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=ADD")
        .to_return(status: 200, body: {request_status: "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})
      finalize_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=FINALIZE")
        .to_return(status: 200, body: finalize_response.to_json, headers: {"Content-Type" => "application/json"})

      result = media_resource.upload_chunked(media_id: MEDIA_ID, file_path: chunked_media_file.path)

      assert_equal MEDIA_ID, result["id"]
      assert_equal "PENDING_UPLOAD", result["media_status"]
      assert_requested(init_stub)
      assert_requested(add_stub, times: 3)
      assert_requested(finalize_stub)
    end
  end

  def test_upload_chunked_is_used_automatically_by_upload_when_the_file_exceeds_the_threshold
    stub_consts(SnapchatApi::Resources::Media, CHUNKED_UPLOAD_THRESHOLD: 10, CHUNK_SIZE: 8) do
      stub_request(:post, "https://adsapi.snapchat.com/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=INIT")
        .to_return(status: 200, body: init_response.to_json, headers: {"Content-Type" => "application/json"})
      add_stub = stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=ADD")
        .to_return(status: 200, body: {request_status: "SUCCESS"}.to_json, headers: {"Content-Type" => "application/json"})
      stub_request(:post, "https://adsapi.snapchat.com/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=FINALIZE")
        .to_return(status: 200, body: finalize_response.to_json, headers: {"Content-Type" => "application/json"})

      result = media_resource.upload(media_id: MEDIA_ID, file_path: chunked_media_file.path)

      assert_equal MEDIA_ID, result["id"]
      assert_requested(add_stub, times: 3)
    end
  end

  def test_upload_uploads_media_file_to_existing_media_record
    with_cassette("_upload/uploads_media_file_to_existing_media_record") do
      media = media_resource.create(
        ad_account_id: AD_ACCOUNT_ID,
        params: {
          name: "Test Upload Media",
          type: "IMAGE"
        }
      )

      uploaded_media = media_resource.upload(
        media_id: media["id"],
        file_path: File.join(__dir__, "../../fixtures/test_image.png")
      )
      assert_has_keys uploaded_media, "id", "name", "type"
      assert_equal media["id"], uploaded_media["id"]
    end
  end

  private

  def media_resource
    @media_resource ||= client.media
  end

  def chunked_media_file
    @chunked_media_file ||= begin
      file = Tempfile.new(["chunked_video", ".mp4"])
      file.binmode
      file.write("a" * 20)
      file.rewind
      file
    end
  end

  def init_response
    {
      request_status: "SUCCESS",
      upload_id: "upload-123",
      add_path: "/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=ADD",
      finalize_path: "/us/v1/media/#{MEDIA_ID}/multipart-upload-v2?action=FINALIZE"
    }
  end

  def finalize_response
    {
      request_status: "SUCCESS",
      result: {
        "id" => MEDIA_ID,
        "name" => "Chunked Video",
        "type" => "VIDEO",
        "media_status" => "PENDING_UPLOAD"
      }
    }
  end

  def stub_consts(mod, consts)
    originals = consts.keys.to_h { |name| [name, mod.const_get(name)] }
    consts.each do |name, value|
      mod.send(:remove_const, name)
      mod.const_set(name, value)
    end
    yield
  ensure
    originals.each do |name, value|
      mod.send(:remove_const, name)
      mod.const_set(name, value)
    end
  end

  def with_cassette(name, &block)
    VCR.use_cassette("SnapchatApi_Resources_Media/#{name}", &block)
  end
end
