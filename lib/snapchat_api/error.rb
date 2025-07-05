module SnapchatApi
  class Error < StandardError
    attr_reader :status_code
    attr_reader :body

    def initialize(message = nil, status_code = nil, body = nil)
      @status_code = status_code
      @body = body
      super(message)
    end
  end

  class AuthenticationError < Error; end

  class AuthorizationError < Error; end

  class InvalidRequestError < Error; end

  class ApiError < Error; end

  class RateLimitError < Error; end
end
