require "simplecov-json"

coverage_dir = './coverage/sapience'
FileUtils.rm_rf coverage_dir

SimpleCov.coverage_dir coverage_dir
SimpleCov.command_name "sapience"
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
