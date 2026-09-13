# dataforseo-ruby

Unofficial, dependency-free Ruby client for [DataForSEO](https://dataforseo.com) Live endpoints.

```ruby
gem "dataforseo-ruby", github: "tonic20/dataforseo-ruby", tag: "v0.1.0"
```

```ruby
client = DataForSeo::Client.new(login: ENV["DATAFORSEO_LOGIN"], password: ENV["DATAFORSEO_PASSWORD"])

response = client.google_ads_search_volume(keywords: ["reverse image search"], language_code: "en")
response.items  # => [{"keyword" => "reverse image search", "search_volume" => 1500000, ...}]
response.cost   # => 0.09
```

`Client.new` also takes `open_timeout:` (10s), `read_timeout:` (120s) and `batch_size:` (1000).

## Typed methods

| Method | Endpoint | Rows |
|---|---|---|
| `google_ads_search_volume(keywords:, language_code:, location_code: nil, search_partners: false)` | keywords_data/google_ads/search_volume/live | `result[]` |
| `bulk_traffic_estimation(targets:, location_name:, language_code:)` | dataforseo_labs/google/bulk_traffic_estimation/live | `result[].items[]` |
| `bulk_ranks(targets:, rank_scale:)` | backlinks/bulk_ranks/live | `result[].items[]` |
| `bulk_spam_score(targets:)` | backlinks/bulk_spam_score/live | `result[].items[]` |
| `backlinks_summary(target:, include_subdomains: true)` | backlinks/summary/live | `result[]` |

Array methods send 1,000 inputs per request. Pass a block to receive each slice's
`Response` (with `#requested` holding only that slice) before the next request is
made, so paid results can be saved as they arrive. Rows come back as the API sent
them; nulls stay `nil` and absent targets stay absent.

`client.post(path, tasks)` reaches other **Live** endpoints. Task-based endpoints
(`20100` task created, results by GET) are not supported.

## Errors

Every transport, protocol or API failure is a `DataForSeo::Error`:

- `ConnectionError` — timeouts, DNS, TLS, resets, unparseable bodies
- `ApiError` (`#status_code`, `#status_message`, `#path`, `#task_id`, `#http_status`)
  - `AuthenticationError` (40100, HTTP 401)
  - `PaymentRequired` (40200, 40210, HTTP 402)
  - `RateLimitError` (40202, 40209, HTTP 429)
  - `TransientError` (50301, 50303, 50401, HTTP 5xx)

The client does not retry or pace. Know before you call:

- Google Ads Live endpoints allow 12 requests per minute per account.
- Google Ads keywords: at most 80 characters and 10 words (raises `ArgumentError`);
  some symbols and emoji are rejected by the API and fail the whole request;
  similar keywords in one request may share a combined volume.
- One malformed target voids a `bulk_spam_score` request (0 items, 0 cost).
- A timeout after the API accepted a request can still be charged; retrying pays again.

## Testing

```ruby
require "dataforseo/testing"

transport = DataForSeo::Testing::FakeTransport.new(
  DataForSeo::Testing.ok_body(result: [{ "keyword" => "x", "search_volume" => 10 }])
)
client = DataForSeo::Client.new(login: "x", password: "y", transport:)
transport.calls # => [[path, payload], ...]
```

A queued `Exception` instance is raised instead of returned.
