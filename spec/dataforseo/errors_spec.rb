# frozen_string_literal: true

RSpec.describe "DataForSeo errors" do
  {
    40100 => DataForSeo::AuthenticationError,
    40200 => DataForSeo::PaymentRequired,
    40210 => DataForSeo::PaymentRequired,
    40202 => DataForSeo::RateLimitError,
    40209 => DataForSeo::RateLimitError,
    50301 => DataForSeo::TransientError,
    50303 => DataForSeo::TransientError,
    50401 => DataForSeo::TransientError
  }.each do |code, klass|
    it "maps #{code} to #{klass}" do
      error = DataForSeo.api_error(status_code: code, status_message: "m", path: "/v3/x", task_id: "t1")

      expect(error).to be_an_instance_of(klass)
      expect(error).to have_attributes(status_code: code, status_message: "m", path: "/v3/x", task_id: "t1")
      expect(error.message).to include(code.to_s, "/v3/x")
    end
  end

  # Exact codes only: a prefix rule would turn 40201 or 50300 into a class the
  # caller retries or aborts on without anyone having chosen that.
  it "maps an unlisted code in a listed family to a plain ApiError" do
    expect(DataForSeo.api_error(status_code: 40201, status_message: "m", path: "/p")).to be_an_instance_of(DataForSeo::ApiError)
    expect(DataForSeo.api_error(status_code: 50300, status_message: "m", path: "/p")).to be_an_instance_of(DataForSeo::ApiError)
  end

  it "maps a missing status code to a plain ApiError" do
    expect(DataForSeo.api_error(status_code: nil, status_message: nil, path: "/p")).to be_an_instance_of(DataForSeo::ApiError)
  end

  { 401 => DataForSeo::AuthenticationError, 402 => DataForSeo::PaymentRequired,
    429 => DataForSeo::RateLimitError, 500 => DataForSeo::TransientError,
    503 => DataForSeo::TransientError, 404 => DataForSeo::ApiError }.each do |status, klass|
    it "maps HTTP #{status} to #{klass}" do
      error = DataForSeo.http_error(http_status: status, path: "/v3/x")

      expect(error).to be_an_instance_of(klass)
      expect(error.http_status).to eq(status)
    end
  end

  it "puts every class under DataForSeo::Error" do
    [DataForSeo::ConnectionError, DataForSeo::ApiError, DataForSeo::AuthenticationError,
     DataForSeo::PaymentRequired, DataForSeo::RateLimitError, DataForSeo::TransientError].each do |klass|
      expect(klass.ancestors).to include(DataForSeo::Error)
    end
  end
end
