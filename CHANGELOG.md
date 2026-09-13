# Changelog

## 0.1.1 — 2026-09-13

- Non-object JSON error bodies are classified by HTTP status instead of raising TypeError/NoMethodError.

## 0.1.0 — 2026-09-13

- Client for DataForSEO Live endpoints with typed errors and slicing.
- Typed methods: google_ads_search_volume, bulk_traffic_estimation, bulk_ranks,
  bulk_spam_score, backlinks_summary.
- DataForSeo::Testing::FakeTransport.
