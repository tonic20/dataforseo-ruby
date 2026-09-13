# frozen_string_literal: true

RSpec.describe "typed endpoints" do
  def client(*bodies)
    @transport = DataForSeo::Testing::FakeTransport.new(*bodies)
    DataForSeo::Client.new(login: "l", password: "p", transport: @transport)
  end

  def sent_path = @transport.calls.first.first
  def sent_task = @transport.calls.first.last.first

  describe "#google_ads_search_volume" do
    it "reads rows directly from result[], nulls kept" do
      response = client(fixture("google_ads_search_volume"))
        .google_ads_search_volume(keywords: ["reverse image search", "shopify spy", "zzqx unknown phrase 4471"],
                                  language_code: "en")

      expect(response.items).not_to be_empty
      expect(response.items.map { it["keyword"] }).to include("reverse image search")
      expect(response.items.find { it["keyword"] == "reverse image search" }["search_volume"]).to be_a(Integer)
    end

    it "sends worldwide by omitting location entirely" do
      client(fixture("google_ads_search_volume")).google_ads_search_volume(keywords: %w[a], language_code: "en")

      expect(sent_path).to eq("/v3/keywords_data/google_ads/search_volume/live")
      expect(sent_task).to eq("keywords" => %w[a], "language_code" => "en", "search_partners" => false)
    end

    it "sends a location when given one" do
      client(fixture("google_ads_search_volume")).google_ads_search_volume(keywords: %w[a], language_code: "en",
                                                                           location_code: 2840)

      expect(sent_task["location_code"]).to eq(2840)
    end

    it "refuses an over-long or over-worded keyword before any request" do
      c = client
      expect { c.google_ads_search_volume(keywords: ["a" * 81], language_code: "en") }.to raise_error(ArgumentError)
      expect { c.google_ads_search_volume(keywords: [(%w[w] * 11).join(" ")], language_code: "en") }
        .to raise_error(ArgumentError)
      expect(@transport.calls).to be_empty
    end
  end

  describe "#bulk_traffic_estimation" do
    it "reads result[].items[] and sends location and language" do
      response = client(fixture("bulk_traffic_estimation"))
        .bulk_traffic_estimation(targets: %w[futuretools.io startupbuffer.com], location_name: "United States",
                                 language_code: "en")

      expect(response.items.map { it["target"] }).to include("futuretools.io")
      expect(sent_path).to eq("/v3/dataforseo_labs/google/bulk_traffic_estimation/live")
      expect(sent_task).to eq("targets" => %w[futuretools.io startupbuffer.com], "location_name" => "United States",
                              "language_code" => "en")
    end

    it "requires location and language" do
      expect { client.bulk_traffic_estimation(targets: %w[a.com]) }.to raise_error(ArgumentError)
    end
  end

  describe "#bulk_ranks" do
    it "reads result[].items[] and always names the scale" do
      response = client(fixture("bulk_ranks")).bulk_ranks(targets: %w[futuretools.io g2.com], rank_scale: "one_thousand")

      expect(response.items.map { it["target"] }).to include("g2.com")
      expect(sent_path).to eq("/v3/backlinks/bulk_ranks/live")
      expect(sent_task).to eq("targets" => %w[futuretools.io g2.com], "rank_scale" => "one_thousand")
    end

    # The API's default once moved seo's DR column onto a non-convertible scale.
    it "has no default scale" do
      expect { client.bulk_ranks(targets: %w[a.com]) }.to raise_error(ArgumentError)
    end
  end

  describe "#bulk_spam_score" do
    it "reads result[].items[], keeps nulls, sends no location" do
      response = client(fixture("bulk_spam_score")).bulk_spam_score(targets: %w[g2.com viberank.dev])

      expect(response.items.map { it["target"] }).to include("g2.com")
      expect(sent_path).to eq("/v3/backlinks/bulk_spam_score/live")
      expect(sent_task).to eq("targets" => %w[g2.com viberank.dev])
    end
  end

  describe "#backlinks_summary" do
    it "reads the single item from result[]" do
      response = client(fixture("backlinks_summary")).backlinks_summary(target: "kopylov.net")

      expect(response.items.size).to eq(1)
      expect(response.items.first.dig("info", "target_spam_score")).not_to be_nil
      expect(sent_path).to eq("/v3/backlinks/summary/live")
      expect(sent_task).to eq("target" => "kopylov.net", "include_subdomains" => true)
      expect(response.requested).to eq(["kopylov.net"])
    end
  end

  it "passes each slice to the block of an array endpoint" do
    body = DataForSeo::Testing.ok_body(result: [{ "items" => [] }])
    c = DataForSeo::Client.new(login: "l", password: "p", batch_size: 1,
                               transport: DataForSeo::Testing::FakeTransport.new(body, body))
    seen = []

    c.bulk_spam_score(targets: %w[a.com b.com]) { seen << it.requested }

    expect(seen).to eq([%w[a.com], %w[b.com]])
  end
end
