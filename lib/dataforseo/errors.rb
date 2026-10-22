# frozen_string_literal: true

module DataForSeo
  # Every transport, protocol or API failure. A caller's retry_on names this
  # (or a subclass) and nothing else, so nothing may escape as its own class.
  class Error < StandardError; end

  class ConnectionError < Error; end

  class ApiError < Error
    attr_reader :status_code, :status_message, :path, :task_id, :http_status

    def initialize(message = nil, status_code: nil, status_message: nil, path: nil, task_id: nil, http_status: nil)
      @status_code = status_code
      @status_message = status_message
      @path = path
      @task_id = task_id
      @http_status = http_status
      head = ["DataForSEO", status_code || (http_status && "HTTP #{http_status}"), "on #{path}"].compact.join(" ")
      super(message || (status_message ? "#{head}: #{status_message}" : head))
    end
  end

  class AuthenticationError < ApiError; end
  class PaymentRequired < ApiError; end
  class RateLimitError < ApiError; end
  class TransientError < ApiError; end
  class TaskNotReady < ApiError; end

  # https://docs.dataforseo.com/v3/appendix/errors/
  API_ERRORS = {
    40100 => AuthenticationError,
    40200 => PaymentRequired, 40210 => PaymentRequired,
    40202 => RateLimitError, 40209 => RateLimitError,
    50301 => TransientError, 50303 => TransientError, 50401 => TransientError,
    40601 => TaskNotReady, 40602 => TaskNotReady
  }.freeze

  HTTP_ERRORS = { 401 => AuthenticationError, 402 => PaymentRequired, 429 => RateLimitError }.freeze

  def self.api_error(status_code:, status_message:, path:, task_id: nil)
    API_ERRORS.fetch(status_code, ApiError)
      .new(status_code:, status_message:, path:, task_id:)
  end

  def self.http_error(http_status:, path:, status_code: nil, status_message: nil)
    klass = HTTP_ERRORS.fetch(http_status) { http_status >= 500 ? TransientError : ApiError }
    klass.new(http_status:, path:, status_code:, status_message:)
  end
end
