# frozen_string_literal: true

module DataForSeo
  # require "dataforseo/testing" in a test suite; never loaded by the gem itself.
  module Testing
    class FakeTransport
      attr_reader :calls

      def initialize(*bodies)
        @bodies = bodies
        @calls = []
      end

      def call(path, payload)
        @calls << [path, payload]
        raise "FakeTransport called more times than it has bodies" if @bodies.empty?

        body = @bodies.shift
        raise body if body.is_a?(Exception)

        body
      end
    end

    def self.ok_body(result:, cost: 0.0)
      { "status_code" => 20000, "status_message" => "Ok.", "cost" => cost,
        "tasks" => [{ "id" => "fake-task", "status_code" => 20000, "status_message" => "Ok.",
                      "cost" => cost, "result" => result }] }
    end

    def self.error_body(status_code:, status_message: "Error", on: :envelope)
      if on == :task
        { "status_code" => 20000, "status_message" => "Ok.", "cost" => 0.0,
          "tasks" => [{ "id" => "fake-task", "status_code" => status_code, "status_message" => status_message }] }
      else
        { "status_code" => status_code, "status_message" => status_message, "tasks" => [] }
      end
    end
  end
end
