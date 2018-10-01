# frozen_string_literal: true
require "simplecov"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sapience"
require "logger"
require "rspec/its"
require "pry-nav"
require "memory_profiler"
require "active_support/testing/time_helpers"

require_relative "support/mock_logger"
require_relative "support/log_factory"
require_relative "support/file_helper"
require_relative "support/config_helper"
require_relative "support/rspec_prof"

TS_REGEX ||= '\d+-\d+-\d+ \d+:\d+:\d+.\d+'

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
  # config.before(:all) do |example|
  #   MemoryProfiler.report(allow_files: "sapience") { example.run }
  #     .pretty_print(to_file: "tmp/full_profile.mem")
  # end

  # config.before(:suite) do
  #   RubyProf.start
  # end

  # config.after(:suite) do
  #   result = RubyProf.stop
  #   printer = RubyProf::MultiPrinter.new(result)
  #   printer.print(path: "tmp", profile: "profile")
  # end

  config.before(:each) do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("APP_NAME").and_return("Sapience RSpec")
    Sapience.configure do |c|
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
