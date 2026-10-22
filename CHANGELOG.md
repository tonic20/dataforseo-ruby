# Changelog

## 0.3.0 — 2026-10-22

- google_organic_task_post returns task-level rejections in tasks[] instead of raising
  (accepted tasks are already billed) and yields each batch as it is posted.

## 0.2.0 — 2026-10-22

- Google organic Standard queue: google_organic_task_post (accepts 20100) and
  google_organic_task_get (advanced, GET); TaskNotReady for 40601/40602.
- HttpTransport sends GET when the payload is nil.

## 0.1.1 — 2026-09-13

- Non-object JSON error bodies are classified by HTTP status instead of raising TypeError/NoMethodError.

## 0.1.0 — 2026-09-13

- Client for DataForSEO Live endpoints with typed errors and slicing.
- Typed methods: google_ads_search_volume, bulk_traffic_estimation, bulk_ranks,
  bulk_spam_score, backlinks_summary.
- DataForSeo::Testing::FakeTransport.
