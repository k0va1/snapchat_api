module SnapchatApi
  module Resources
    class Account < Base
      def list_all(organization_id:, params: {})
        params[:limit] ||= 50

        accounts = []
        next_link = "organizations/#{organization_id}/adaccounts?limit=#{params[:limit]}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body["paging"]["next_link"]
          accounts.concat(response.body["adaccounts"].map { |el| el["adaccount"] })
          break if next_link.nil?
        end

        accounts
      end
    end
  end
end
