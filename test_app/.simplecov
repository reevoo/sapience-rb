require "simplecov-json"

coverage_dir = '../coverage/rails'
FileUtils.rm_rf coverage_dir

SimpleCov.coverage_dir coverage_dir
SimpleCov.command_name "rails"
SimpleCov.maximum_coverage_drop 1
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]
SimpleCov.start :rails do
  profiles.delete(:root_filter)
  filters.clear
  add_filter do |src|
    if src.filename =~ /sapience\-rb/
      src.filename.include?("test_app")
    else
      true
    end
  end

  add_group "Sapience", "../"
end
