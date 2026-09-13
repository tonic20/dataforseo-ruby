# frozen_string_literal: true

# One-off: records real response bodies for the typed endpoints' specs.
# Costs roughly $0.2. Credentials come from the environment and are never written.
require "json"
require_relative "../lib/dataforseo"

transport = DataForSeo::HttpTransport.new(login: ENV.fetch("DATAFORSEO_LOGIN"),
                                          password: ENV.fetch("DATAFORSEO_PASSWORD"),
                                          open_timeout: 10, read_timeout: 120)
calls = {
  "google_ads_search_volume" => ["/v3/keywords_data/google_ads/search_volume/live",
                                 [{ "keywords" => ["reverse image search", "shopify spy", "zzqx unknown phrase 4471"],
                                    "language_code" => "en", "search_partners" => false }]],
  "bulk_traffic_estimation" => ["/v3/dataforseo_labs/google/bulk_traffic_estimation/live",
                                [{ "targets" => %w[futuretools.io startupbuffer.com], "location_name" => "United States",
                                   "language_code" => "en" }]],
  "bulk_ranks" => ["/v3/backlinks/bulk_ranks/live", [{ "targets" => %w[futuretools.io g2.com], "rank_scale" => "one_thousand" }]],
  "bulk_spam_score" => ["/v3/backlinks/bulk_spam_score/live", [{ "targets" => %w[g2.com viberank.dev] }]],
  "backlinks_summary" => ["/v3/backlinks/summary/live", [{ "target" => "kopylov.net", "include_subdomains" => true }]]
}

calls.each do |name, (path, payload)|
  body = transport.call(path, payload)
  File.write(File.expand_path("../spec/fixtures/#{name}.json", __dir__), "#{JSON.pretty_generate(body)}\n")
  puts "#{name}: status #{body["status_code"]}, cost #{body["cost"]}"
end
