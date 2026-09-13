# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"

module DataForSeo
  class HttpTransport
    HOST = "api.dataforseo.com"

    NETWORK_ERRORS = [
      Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError,
      OpenSSL::SSL::SSLError, IOError, EOFError
    ].freeze

    def initialize(login:, password:, open_timeout:, read_timeout:)
      @login = login
      @password = password
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def call(path, payload)
      request = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
      request.basic_auth(@login, @password)
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(HOST, 443, use_ssl: true,
                                 open_timeout: @open_timeout, read_timeout: @read_timeout) { it.request(request) }
      parse(path, response)
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, "#{e.class}: #{e.message}"
    end

    private

    # HTTP status first: some failures arrive as a non-2xx with an HTML body,
    # and parsing that first would report a credentials problem as a network one.
    def parse(path, response)
      status = response.code.to_i
      body = begin
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        nil
      end

      return body if body.is_a?(Hash) && (status.between?(200, 299) || body.key?("status_code"))
      raise ConnectionError, "unparseable body from #{path} (HTTP #{status})" if status.between?(200, 299)

      raise DataForSeo.http_error(http_status: status, path:)
    end
  end
end
