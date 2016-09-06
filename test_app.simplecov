require "simplecov-json"
require "codeclimate-test-reporter"
require "coveralls"

CodeClimate::TestReporter.start
SimpleCov.maximum_coverage_drop 1

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
