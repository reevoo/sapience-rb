if ENV['CODECLIMATE_REPO_TOKEN']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start

  # require "coveralls"
  # Coveralls.wear!
else
  require "simplecov-json"
  SimpleCov.maximum_coverage_drop 1

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
  ]

  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/bin/"
    add_filter "/gemfiles/"
  end

end