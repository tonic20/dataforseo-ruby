# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "timeout"
require "zlib"

module DataForSeo
  class HttpTransport
    HOST = "api.dataforseo.com"

    # Timeout::Error covers Net::Open/Read/WriteTimeout; Net::HTTP requests gzip
    # and doesn't rescue inflate errors itself, hence Zlib::Error.
    NETWORK_ERRORS = [
      Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, IOError, EOFError,
      Net::ProtocolError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Zlib::Error
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

      if status.between?(200, 299)
        return body if body.is_a?(Hash)
        raise ConnectionError, "unparseable body from #{path} (HTTP #{status})"
      end

      # A non-2xx with a status_code we classify (e.g. 401/40100) still goes to the
      # client, so it raises the same class as the same code would on a 2xx.
      return body if body.is_a?(Hash) && API_ERRORS.key?(body["status_code"])

      status_code, status_message = body.values_at("status_code", "status_message") if body.is_a?(Hash)
      raise DataForSeo.http_error(http_status: status, path:, status_code:, status_message:)
    end
  end
end
