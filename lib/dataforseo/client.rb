# frozen_string_literal: true

module DataForSeo
  module GoogleAds
    MAX_KEYWORD_LENGTH = 80
    MAX_KEYWORD_WORDS = 10

    def self.validate!(keywords)
      bad = keywords.find { it.length > MAX_KEYWORD_LENGTH || it.split.size > MAX_KEYWORD_WORDS }
      raise ArgumentError, "keyword exceeds Google Ads limits (80 chars, 10 words): #{bad.inspect}" if bad
    end
  end

  class Client
    OPEN_TIMEOUT = 10
    # seo's bulk_traffic_estimation took 34.6s for 98 targets; a slice holds 1,000.
    READ_TIMEOUT = 120
    BATCH_SIZE = 1000
    OK = 20000

    RESULT = ->(task) { Array(task["result"]) }
    ITEMS = ->(task) { Array(task["result"]).flat_map { Array(it["items"]) } }

    def initialize(login:, password:, transport: nil, open_timeout: OPEN_TIMEOUT,
                   read_timeout: READ_TIMEOUT, batch_size: BATCH_SIZE)
      @transport = transport || HttpTransport.new(login:, password:, open_timeout:, read_timeout:)
      @batch_size = batch_size
    end

    # Live endpoints only: a task-based endpoint's 20100 "created" raises here.
    def post(path, tasks, requested: [], extract: RESULT)
      body = @transport.call(path, tasks)
      check!(body, path)
      tasks = Array(body["tasks"])
      tasks.each { check!(it, path, task_id: it["id"]) }

      Response.new(path:, cost: body["cost"], tasks:, items: tasks.flat_map(&extract), requested:)
    end

    SEARCH_VOLUME_PATH = "/v3/keywords_data/google_ads/search_volume/live"
    TRAFFIC_PATH = "/v3/dataforseo_labs/google/bulk_traffic_estimation/live"
    RANKS_PATH = "/v3/backlinks/bulk_ranks/live"
    SPAM_PATH = "/v3/backlinks/bulk_spam_score/live"
    SUMMARY_PATH = "/v3/backlinks/summary/live"

    # No location means worldwide. Google Ads Live allows 12 requests/minute per
    # account; pacing is the caller's.
    def google_ads_search_volume(keywords:, language_code:, location_code: nil, search_partners: false, &block)
      GoogleAds.validate!(keywords)
      sliced(SEARCH_VOLUME_PATH, keywords, RESULT, block) do |slice|
        { "keywords" => slice, "language_code" => language_code, "location_code" => location_code,
          "search_partners" => search_partners }.compact
      end
    end

    def bulk_traffic_estimation(targets:, location_name:, language_code:, &block)
      sliced(TRAFFIC_PATH, targets, ITEMS, block) do |slice|
        { "targets" => slice, "location_name" => location_name, "language_code" => language_code }
      end
    end

    # rank_scale has no default on purpose.
    def bulk_ranks(targets:, rank_scale:, &block)
      sliced(RANKS_PATH, targets, ITEMS, block) { |slice| { "targets" => slice, "rank_scale" => rank_scale } }
    end

    # Sends no location/language: the endpoint rejects them (40501). One malformed
    # target voids the whole slice.
    def bulk_spam_score(targets:, &block)
      sliced(SPAM_PATH, targets, ITEMS, block) { |slice| { "targets" => slice } }
    end

    def backlinks_summary(target:, include_subdomains: true)
      post(SUMMARY_PATH, [{ "target" => target, "include_subdomains" => include_subdomains }],
           requested: [target], extract: RESULT)
    end

    private

    def check!(envelope, path, task_id: nil)
      return if envelope["status_code"] == OK

      raise DataForSeo.api_error(status_code: envelope["status_code"], status_message: envelope["status_message"],
                                 path:, task_id:)
    end

    def sliced(path, inputs, extract, block)
      responses = inputs.each_slice(@batch_size).map do |slice|
        post(path, [yield(slice)], requested: slice, extract:).tap { block&.call(it) }
      end
      Response.combine(responses, path:, requested: inputs)
    end
  end
end
