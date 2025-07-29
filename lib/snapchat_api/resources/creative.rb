module SnapchatApi
  module Resources
    class Creative < Base
      def list_all(ad_account_id:, params: {})
        params[:limit] ||= 50

        creatives = []
        next_link = "adaccounts/#{ad_account_id}/creatives?limit=#{params[:limit]}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          creatives.concat(response.body["creatives"].map { |el| el["creative"] })
          break if next_link.nil?
        end

        creatives
      end

      def get(creative_id:)
        response = client.request(:get, "creatives/#{creative_id}")
        response.body["creatives"].first["creative"]
      end

      def create(ad_account_id:, params: {})
        creatives_data = {
          creatives: [**params]
        }

        response = client.request(:post, "adaccounts/#{ad_account_id}/creatives", creatives_data)
        response.body["creatives"].first["creative"]
      end

      def update(ad_account_id:, creative_id:, params: {})
        creatives_data = {
          creatives: [**params.merge(id: creative_id, ad_account_id:)]
        }

        response = client.request(:put, "adaccounts/#{ad_account_id}/creatives", creatives_data)
        response.body["creatives"].first["creative"]
      end
    end
  end
end
