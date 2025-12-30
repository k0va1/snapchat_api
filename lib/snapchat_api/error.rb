module SnapchatApi
  class Error < StandardError
    attr_reader :status_code
    attr_reader :body
    attr_reader :request_id

    def initialize(message = nil, status_code = nil, body = nil, request_id = nil)
      @status_code = status_code
      @body = body
      @request_id = request_id
      super(message)
    end
  end

  class AuthenticationError < Error; end

  class AuthorizationError < Error; end

  class InvalidRequestError < Error; end

  class ApiError < Error; end

  class RateLimitError < Error; end

  # Raised when API returns HTTP 200 but request_status is ERROR
  class RequestError < Error
    attr_reader :sub_errors

    def initialize(message = nil, status_code = nil, body = nil, request_id = nil, sub_errors = [])
      @sub_errors = sub_errors
      super(message, status_code, body, request_id)
    end
  end
end
