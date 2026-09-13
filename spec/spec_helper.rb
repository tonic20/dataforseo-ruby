# frozen_string_literal: true

require "json"
require "dataforseo"
require "dataforseo/testing"

FIXTURES = File.expand_path("fixtures", __dir__)

def fixture(name) = JSON.parse(File.read(File.join(FIXTURES, "#{name}.json")))

RSpec.configure do |config|
  config.expect_with(:rspec) { it.include_chain_clauses_in_custom_matcher_descriptions = true }
  config.mock_with(:rspec) { it.verify_partial_doubles = true }
  config.order = :random
  Kernel.srand config.seed
end
