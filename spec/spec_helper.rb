require "simplecov"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sapience"
require "logger"
require "rspec/its"
require "rspec/wait"
require "pry-nav"
require_relative "support/mock_logger"
require_relative "support/log_factory"
require_relative "support/file_helper"

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

  config.before(:each) do |_test|
    Sapience.remove_appenders
  end

  RSpec.configure do |config|
    config.wait_timeout = 2 # seconds
  end
end
