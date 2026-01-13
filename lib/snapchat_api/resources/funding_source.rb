module SnapchatApi
  module Resources
    class FundingSource < Base
      def list_all(organization_id:, params: {})
        params[:limit] ||= 50

        funding_sources = []
        query = URI.encode_www_form(params.compact)
        next_link = "organizations/#{organization_id}/fundingsources?#{query}"

        loop do
          response = client.request(:get, next_link)
          next_link = response.body.dig("paging", "next_link")
          funding_sources.concat(response.body["fundingsources"].map { |el| el["fundingsource"] })
          break if next_link.nil?
        end

        funding_sources
      end

      def get(funding_source_id:)
        response = client.request(:get, "fundingsources/#{funding_source_id}")
        response.body["fundingsources"].first["fundingsource"]
      end
    end
  end
end
