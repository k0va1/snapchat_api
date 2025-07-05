require "faraday"
require "faraday/multipart"
require "faraday/follow_redirects"
require "faraday/retry"
require "snapchat_api/error"

module SnapchatApi
  class Client
    attr_accessor :client_id, :client_secret, :access_token, :refresh_token, :debug

    ADS_HOST = "https://adsapi.snapchat.com"
    ACCOUNTS_HOST = "https://accounts.snapchat.com"

    ADS_CURRENT_API_PATH = "v1"
    ADS_URL = "#{ADS_HOST}/#{ADS_CURRENT_API_PATH}"

    def initialize(client_id:, client_secret:, access_token: nil, refresh_token: nil, debug: false)
      @client_id = client_id
      @client_secret = client_secret
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
      puts response.body

      handle_response(response)
    end

    def handle_response(response)
      return response if response.success?

      status = response.status
      body = response.body
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

    def auth
    end

    def accounts
      @accounts ||= SnapchatApi::Resources::Account.new(self)
    end

    def campaigns
      @campaigns ||= SnapchatApi::Resources::Campaign.new(self)
    end
  end
end
