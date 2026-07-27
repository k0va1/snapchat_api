require "stringio"
require "mime/types"

module SnapchatApi
  module Resources
    class Media < Base
      CHUNKED_UPLOAD_THRESHOLD = 32_000_000
      CHUNK_SIZE = 25 * 1024 * 1024

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
        return upload_chunked(media_id: media_id, file_path: file_path, params: params) if File.size(file_path) > CHUNKED_UPLOAD_THRESHOLD

        mime_type = MIME::Types.type_for(file_path).first.content_type

        upload_params = {
          file: Faraday::UploadIO.new(file_path, mime_type, File.basename(file_path))
        }

        response = client.request(:post, "media/#{media_id}/upload", upload_params, {"Content-Type" => "multipart/form-data"})
        response.body["result"]
      end

      def upload_chunked(media_id:, file_path:, params: {})
        mime_type = MIME::Types.type_for(file_path).first.content_type
        file_name = File.basename(file_path)
        file_size = File.size(file_path)
        number_of_parts = (file_size.to_f / CHUNK_SIZE).ceil

        init_response = client.request(
          :post,
          "media/#{media_id}/multipart-upload-v2?action=INIT",
          {
            file_name: file_name,
            file_size: file_size.to_s,
            number_of_parts: number_of_parts.to_s
          },
          {"Content-Type" => "multipart/form-data"}
        )
        upload_id = init_response.body["upload_id"]
        add_path = init_response.body["add_path"]
        finalize_path = init_response.body["finalize_path"]

        File.open(file_path, "rb") do |file|
          part_number = 1
          while (chunk = file.read(CHUNK_SIZE))
            client.request(
              :post,
              add_path,
              {
                file: Faraday::UploadIO.new(StringIO.new(chunk), mime_type, file_name),
                part_number: part_number.to_s,
                upload_id: upload_id
              },
              {"Content-Type" => "multipart/form-data"}
            )
            part_number += 1
          end
        end

        response = client.request(
          :post,
          finalize_path,
          {upload_id: upload_id, file_name: file_name},
          {"Content-Type" => "multipart/form-data"}
        )
        response.body["result"]
      end

      def preview(media_id:)
        response = client.request(:get, "media/#{media_id}/preview")
        response.body
      end

      def thumbnail(media_id:)
        response = client.request(:get, "media/#{media_id}/thumbnail")
        response.body
      end
    end
  end
end
