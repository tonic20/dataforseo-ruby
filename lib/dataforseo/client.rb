# frozen_string_literal: true

module DataForSeo
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
