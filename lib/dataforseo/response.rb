# frozen_string_literal: true

module DataForSeo
  # requested is what was sent in THIS request, so a caller persisting one
  # slice can tell "omitted from the answer" from "not asked yet".
  class Response
    attr_reader :path, :cost, :tasks, :items, :requested

    def initialize(path:, cost:, tasks:, items:, requested:)
      @path = path
      @cost = cost.to_f
      @tasks = tasks
      @items = items
      @requested = requested
    end

    def self.combine(responses, path:, requested:)
      new(path:, requested:,
          cost: responses.sum(0.0, &:cost),
          tasks: responses.flat_map(&:tasks),
          items: responses.flat_map(&:items))
    end
  end
end
