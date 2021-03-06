require "simplecov-json"

coverage_dir = '../../coverage/grape'
FileUtils.rm_rf coverage_dir

SimpleCov.coverage_dir coverage_dir
SimpleCov.command_name "grape"
SimpleCov.maximum_coverage_drop 1
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]
SimpleCov.start do
  profiles.delete(:root_filter)
  filters.clear
  add_filter do |src|
    if src.filename =~ %r{sapience\-rb|\/usr\/src\/app/}
      src.filename.include?("test_apps/grape")
    else
      true
    end
  end

  add_group "Sapience", "../"
end
