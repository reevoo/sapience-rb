require "simplecov-json"
require "coveralls"
Coveralls.wear!

SimpleCov.refuse_coverage_drop

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter "/gemfiles/"
end
