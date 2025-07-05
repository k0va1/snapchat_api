require "securerandom"

module SnapchatApi
  class Auth
    def initialize(client_id:, client_secret:, redirect_uri:)
      @client_id = client_id
      @client_secret = client_secret
      @redirect_uri = redirect_uri
    end

    def get_authorization_url(scope:)
      params = {
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        response_type: "code",
        scope: DEFAULT_SCOPE,
        state: state
      }

      "#{AUTH_URL}?#{URI.encode_www_form(params)}"
    end

    def get_token(code:)
      response = token_connection.post(TOKEN_URL) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form({
          client_id: @client_id,
          client_secret: @client_secret,
          code: code,
          grant_type: "authorization_code",
          redirect_uri: @redirect_uri
        })
      end

      handle_token_response(response)
    end

    def refresh_token(refresh_token:)
      Rails.logger.info("Refreshing Snapchat refresh_token!")
      response = token_connection.post(TOKEN_URL) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form({
          client_id: @client_id,
          client_secret: @client_secret,
          refresh_token: refresh_token,
          grant_type: "refresh_token"
        })
      end

      handle_token_response(response)
    end

    private

    def token_connection
      @token_connection ||= Faraday.new do |conn|
        conn.request :url_encoded
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_token_response(response)
      if response.success?
        body = response.body
        {
          access_token: body["access_token"],
          refresh_token: body["refresh_token"],
          expires_in: body["expires_in"]
        }
      else
        raise ExternalApi::Snapchat::Error, "Token request failed: #{response.body}"
      end
    end
  end
end
