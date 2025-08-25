require "stringio"
require "mime/types"

module SnapchatApi
  module Resources
    class Media < Base
      def list_all(ad_account_id:, params: {})
        params[:limit] ||= 50

        media_items = []
        next_link = "adaccounts/#{ad_account_id}/media?limit=#{params[:limit]}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          media_items.concat(response.body["media"].map { |el| el["media"] })
          break if next_link.nil?
        end

        media_items
      end

      def get(media_id:)
        response = client.request(:get, "media/#{media_id}")
        response.body["media"].first["media"]
      end

      def create(ad_account_id:, params: {})
        media_data = {
          media: [params]
        }

        response = client.request(:post, "adaccounts/#{ad_account_id}/media", media_data)
        response.body["media"].first["media"]
      end

      def upload(media_id:, file_path:, params: {})
        mime_type = MIME::Types.type_for(file_path).first.content_type

        upload_params = {
          file: Faraday::UploadIO.new(file_path, mime_type, File.basename(file_path))
        }

        response = client.request(:post, "media/#{media_id}/upload", upload_params, {"Content-Type" => "multipart/form-data"})
        response.body["result"]
      end

      def preview(media_id:)
        response = client.request(:get, "media/#{media_id}/preview")
        response.body["preview_url"]
      end
    end
  end
end
