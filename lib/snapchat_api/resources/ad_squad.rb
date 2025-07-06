module SnapchatApi
  module Resources
    class AdSquad < Base
      def list_all(ad_account_id:, params: {})
        params[:limit] ||= 50

        ad_squads = []
        next_link = "adaccounts/#{ad_account_id}/adsquads?limit=#{params[:limit]}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          ad_squads.concat(response.body["adsquads"].map { |el| el["adsquad"] })
          break if next_link.nil?
        end

        ad_squads
      end

      def get(ad_squad_id:)
        response = client.request(:get, "adsquads/#{ad_squad_id}")
        response.body["adsquads"].first["adsquad"]
      end

      def create(campaign_id:, params: {})
        ad_squads_data = {
          adsquads: [**params.merge(campaign_id: campaign_id)]
        }

        response = client.request(:post, "campaigns/#{campaign_id}/adsquads", ad_squads_data)
        response.body["adsquads"].first["adsquad"]
      end

      def update(campaign_id:, ad_squad_id:, params: {})
        ad_squads_data = {
          adsquads: [**params.merge(id: ad_squad_id, campaign_id:)]
        }

        response = client.request(:put, "campaigns/#{campaign_id}/adsquads", ad_squads_data)
        response.body["adsquads"].first["adsquad"]
      end

      def delete(ad_squad_id:)
        response = client.request(:delete, "adsquads/#{ad_squad_id}")
        response.success?
      end

      def get_stats(ad_squad_id:, params: {})
        response = client.request(:get, "adsquads/#{ad_squad_id}/stats", params)
        response.body
      end
    end
  end
end
