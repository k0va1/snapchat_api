module SnapchatApi
  module Resources
    class Organization < Base
      def list_all(params: {})
        params[:limit] ||= 50

        organizations = []
        query = URI.encode_www_form(params.compact)
        next_link = "me/organizations?#{query}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body.dig("paging", "next_link")
          organizations.concat(response.body["organizations"].map { |el| el["organization"] })
          break if next_link.nil?
        end

        organizations
      end

      def get(organization_id:)
        response = client.request(:get, "organizations/#{organization_id}")
        response.body["organizations"].first["organization"]
      end
    end
  end
end
