require "simplecov-json"
require 'codeclimate-test-reporter'
require "coveralls"

SimpleCov.refuse_coverage_drop

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
  CodeClimate::TestReporter::Formatter,
  Coveralls::SimpleCov::Formatter,
]

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/gemfiles/"
end
