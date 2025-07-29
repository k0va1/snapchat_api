module SnapchatApi
  module Resources
    class Ad < Base
      def create(ad_squad_id:, params:)
        ads_data = {ads: [**params]}
        response = client.request(:post, "adsquads/#{ad_squad_id}/ads", ads_data)

        response.body["ads"].first["ad"]
      end

      def list_all_by(entity_id:, entity: :ad_squad, params: {})
        params[:limit] ||= 50

        ads = []

        next_link = case entity
        when :ad_squad
          "adsquads/#{entity_id}/ads?limit=#{params[:limit]}"
        when :ad_account
          "adaccounts/#{entity_id}/ads?limit=#{params[:limit]}"
        when :campaign
          "campaigns/#{entity_id}/ads?limit=#{params[:limit]}"
        else
          raise ArgumentError, "Invalid entity type: #{entity}. Must be :ad_squad, :ad_account, or :campaign."
        end

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          ads.concat(response.body["ads"].map { |el| el["ad"] })
          break if next_link.nil?
        end

        ads
      end

      def get(ad_id:)
        response = client.request(:get, "ads/#{ad_id}")
        response.body["ads"].first["ad"]
      end

      def delete(ad_id:)
        response = client.request(:delete, "ads/#{ad_id}")
        response.success?
      end

      def update(ad_squad_id:, params:)
        ad_data = {
          ads: [**params.merge(ad_squad_id: ad_squad_id)]
        }

        response = client.request(:put, "adsquads/#{ad_squad_id}/ads", ad_data)
        response.body["ads"].first["ad"]
      end

      def get_stats(ad_id:, params: {})
        response = client.request(:get, "ads/#{ad_id}/stats", params)
        response.body
      end
    end
  end
end
