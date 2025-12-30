require "faraday"
require "faraday/multipart"
require "faraday/follow_redirects"
require "faraday/retry"
require "snapchat_api/error"

module SnapchatApi
  class Client
    attr_accessor :client_id, :client_secret, :access_token, :refresh_token, :debug, :redirect_uri

    ADS_HOST = "https://adsapi.snapchat.com"
    ACCOUNTS_HOST = "https://accounts.snapchat.com"

    ADS_CURRENT_API_PATH = "v1"
    ADS_URL = "#{ADS_HOST}/#{ADS_CURRENT_API_PATH}"

    def initialize(client_id:, client_secret:, redirect_uri: nil, access_token: nil, refresh_token: nil, debug: false)
      @client_id = client_id
      @client_secret = client_secret
      @redirect_uri = redirect_uri
      @access_token = access_token
      @refresh_token = refresh_token
      @debug = debug
    end

    def connection
      @connection ||= Faraday.new(url: ADS_URL) do |conn|
        conn.headers["Authorization"] = "Bearer #{@access_token}"
        conn.headers["Content-Type"] = "application/json"

        conn.options.timeout = 60
        conn.options.open_timeout = 30

        conn.request :multipart
        conn.use Faraday::FollowRedirects::Middleware
        conn.use Faraday::Retry::Middleware, max: 3

        conn.response :json

        conn.response :logger if @debug

        conn.adapter Faraday.default_adapter
      end
    end

    def request(method, path, params = {}, headers = {})
      response = connection.run_request(method, path, nil, headers) do |req|
        case method
        when :get, :delete
          req.params = params
        when :post, :put
          if headers["Content-Type"] == "multipart/form-data"
            req.options.timeout = 120
            req.body = {}
            params.each do |key, value|
              req.body[key.to_sym] = value
            end
          else
            req.body = JSON.generate(params) unless params.empty?
          end
        end
      end

      handle_response(response)
    end

    def refresh_tokens!
      response = Faraday.post("#{ACCOUNTS_HOST}/login/oauth2/access_token") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          client_id: @client_id,
          client_secret: @client_secret,
          refresh_token: @refresh_token,
          grant_type: "refresh_token"
        )
      end
      handle_response(response)
      body = JSON.parse(response.body)

      @access_token = body["access_token"]
      @refresh_token = body["refresh_token"]
    end

    def get_authorization_url(scope: "snapchat-marketing-api")
      params = {
        client_id: @client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: scope,
        state: state
      }

      "https://accounts.snapchat.com/accounts/oauth2/auth?#{URI.encode_www_form(params)}"
    end

    def get_tokens(code:)
      response = Faraday.post("#{ACCOUNTS_HOST}/login/oauth2/access_token") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form({
          client_id: @client_id,
          client_secret: @client_secret,
          code: code,
          grant_type: "authorization_code",
          redirect_uri: redirect_uri
        })
      end
      handle_response(response)
      JSON.parse(response.body)
    end

    def accounts
      @accounts ||= SnapchatApi::Resources::Account.new(self)
    end

    def campaigns
      @campaigns ||= SnapchatApi::Resources::Campaign.new(self)
    end

    def ad_squads
      @ad_squads ||= SnapchatApi::Resources::AdSquad.new(self)
    end

    def media
      @media ||= SnapchatApi::Resources::Media.new(self)
    end

    def creatives
      @creatives ||= SnapchatApi::Resources::Creative.new(self)
    end

    def ads
      @ads ||= SnapchatApi::Resources::Ad.new(self)
    end

    private

    def handle_response(response)
      body = response.body
      status = response.status

      # Check for request-level errors (API returns 200 but request_status is ERROR)
      if response.success? && body.is_a?(Hash)
        check_request_status_error(body, status)
        return response
      end

      return response if response.success?

      error_message = body.is_a?(Hash) ? body&.dig("message") : body

      klass = case status
      when 401
        SnapchatApi::AuthenticationError
      when 403
        SnapchatApi::AuthorizationError
      when 429
        SnapchatApi::RateLimitError
      when 400..499
        SnapchatApi::InvalidRequestError
      when 500..599
        SnapchatApi::ApiError
      else
        SnapchatApi::Error
      end

      raise klass.new(error_message || "HTTP #{status}", status, body)
    end

    def check_request_status_error(body, status)
      return unless body["request_status"] == "ERROR"

      request_id = body["request_id"]
      sub_errors = extract_sub_errors(body)
      error_message = build_error_message(body, sub_errors)

      raise SnapchatApi::RequestError.new(error_message, status, body, request_id, sub_errors)
    end

    def extract_sub_errors(body)
      sub_errors = []

      # Look for sub-request errors in various response keys
      # The API may return errors under different keys depending on the endpoint
      possible_keys = %w[creatives ads campaigns ad_squads media adaccounts]

      possible_keys.each do |key|
        next unless body[key].is_a?(Array)

        body[key].each do |item|
          if item.is_a?(Hash) && item["sub_request_status"] == "ERROR"
            sub_errors << {
              reason: item["sub_request_error_reason"],
              status: item["sub_request_status"]
            }
          end
        end
      end

      sub_errors
    end

    def build_error_message(body, sub_errors)
      if sub_errors.any?
        messages = sub_errors.map { |e| e[:reason] }.compact
        messages.join("; ")
      else
        body["debug_message"] || body["display_message"] || "Request failed with status ERROR"
      end
    end
  end
end
