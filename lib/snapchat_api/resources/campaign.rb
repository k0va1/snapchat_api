module SnapchatApi
  module Resources
    class Campaign < Base
      def list_all(ad_account_id:, params: {})
        params[:limit] ||= 50

        campaigns = []
        next_link = "adaccounts/#{ad_account_id}/campaigns?limit=#{params[:limit]}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          campaigns.concat(response.body["campaigns"].map { |el| el["campaign"] })
          break if next_link.nil?
        end

        campaigns
      end

      def get(ad_account_id:, campaign_id:)
        response = client.request(:get, "campaigns/#{campaign_id}")
        response.body["campaigns"].first["campaign"]
      end

      def create(ad_account_id:, params: {})
        campaigns_data = {
          campaigns: [**params]
        }

        response = client.request(:post, "adaccounts/#{ad_account_id}/campaigns", campaigns_data)
        response.body["campaigns"].first["campaign"]
      end

      def update(ad_account_id:, campaign_id:, params: {})
        campaigns_data = {
          campaigns: [**params.merge(id: campaign_id, ad_account_id:)]
        }

        response = client.request(:put, "adaccounts/#{ad_account_id}/campaigns", campaigns_data)
        response.body["campaigns"].first["campaign"]
      end

      def delete(campaign_id:)
        response = client.request(:delete, "campaigns/#{campaign_id}")
        response.success?
      end

      def get_stats(campaign_id:, params: {})
        response = client.request(:get, "campaigns/#{campaign_id}/stats", params)
        response.body
      end
    end
  end
end
