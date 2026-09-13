# frozen_string_literal: true

require "net/http"

RSpec.describe DataForSeo::HttpTransport do
  let(:transport) { described_class.new(login: "l", password: "p", open_timeout: 10, read_timeout: 120) }

  def http_response(code, body, klass = Net::HTTPResponse::CODE_TO_OBJ.fetch(code.to_s))
    response = klass.new("1.1", code.to_s, "msg")
    allow(response).to receive(:body).and_return(body)
    response
  end

  def stub_http(response = nil, &block)
    allow(Net::HTTP).to receive(:start) do |host, port, **options, &session|
      expect([host, port, options.slice(:use_ssl, :open_timeout, :read_timeout)])
        .to eq(["api.dataforseo.com", 443, { use_ssl: true, open_timeout: 10, read_timeout: 120 }])
      block ? block.call : session.call(double(request: response))
    end
  end

  it "POSTs JSON with basic auth and returns the parsed body" do
    sent = nil
    allow(Net::HTTP).to receive(:start) do |*_args, **_options, &session|
      http = double
      allow(http).to receive(:request) { |request| sent = request; http_response(200, '{"status_code":20000}') }
      session.call(http)
    end

    expect(transport.call("/v3/x", [{ "a" => 1 }])).to eq("status_code" => 20000)
    expect(sent.path).to eq("/v3/x")
    expect(sent["Content-Type"]).to eq("application/json")
    expect(sent["Authorization"]).to eq("Basic #{["l:p"].pack("m0")}")
    expect(JSON.parse(sent.body)).to eq([{ "a" => 1 }])
  end

  [Net::ReadTimeout, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET,
   OpenSSL::SSL::SSLError, EOFError, IOError].each do |klass|
    it "turns #{klass} into ConnectionError and keeps the cause" do
      stub_http { raise klass }

      expect { transport.call("/v3/x", []) }.to raise_error(DataForSeo::ConnectionError) { |error|
        expect(error.cause).to be_a(klass)
      }
    end
  end

  it "turns an unparseable 200 body into ConnectionError" do
    stub_http(http_response(200, "<html>oops</html>"))

    expect { transport.call("/v3/x", []) }.to raise_error(DataForSeo::ConnectionError, /unparseable/)
  end

  # A bad password answered with HTML must not look like a network blip, or a
  # caller's retry_on would retry it.
  { 401 => DataForSeo::AuthenticationError, 402 => DataForSeo::PaymentRequired,
    404 => DataForSeo::ApiError, 500 => DataForSeo::TransientError }.each do |status, klass|
    it "raises #{klass} for HTTP #{status} with a non-JSON body" do
      stub_http(http_response(status, "<html>nope</html>"))

      expect { transport.call("/v3/x", []) }.to raise_error(klass) { expect(it.http_status).to eq(status) }
    end
  end

  it "returns a non-2xx JSON envelope so the client maps its own status code" do
    stub_http(http_response(401, '{"status_code":40100,"status_message":"not authorized"}'))

    expect(transport.call("/v3/x", [])).to eq("status_code" => 40100, "status_message" => "not authorized")
  end
end
