require "simplecov"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sapience"
require "logger"
require "rspec/its"
require "pry-nav"
require "active_support/testing/time_helpers"

require_relative "support/mock_logger"
require_relative "support/log_factory"
require_relative "support/file_helper"
require_relative "support/config_helper"

TS_REGEX ||= '\d+-\d+-\d+ \d+:\d+:\d+.\d+'.freeze

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = "spec/examples.txt"
  # config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  # config.profile_examples = 10
  config.order = :random

  Kernel.srand config.seed

  config.before(:each) do
    Sapience.configure do |c|
      c.app_name = "Sapience RSpec"
      c.log_executor = :immediate_executor
    end
  end

  config.before(:each) do |_example|
    Sapience.reset!
  end

  config.extend ConfigHelper
  config.include ConfigHelper
  config.include ActiveSupport::Testing::TimeHelpers
end
