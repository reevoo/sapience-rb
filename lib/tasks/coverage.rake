COVERAGE_FILE = ".simplecov".freeze
COVERAGE_BKP_FILE = ".simplecov.bkp".freeze

def coverage_dir
  p File.join(Dir.pwd, "coverage")
end

def hide_coverage_config
  FileUtils.mv COVERAGE_FILE, COVERAGE_BKP_FILE if File.exist?(COVERAGE_FILE)
end

def unhide_coverage_config
  FileUtils.mv COVERAGE_BKP_FILE, COVERAGE_FILE if File.exist?(COVERAGE_BKP_FILE)
end

namespace :coverage do
  task :merge do
    hide_coverage_config
    require "json"
    require "simplecov/version"
    require "simplecov/result"
    require "simplecov-html"
    require "simplecov-json"

    coverage_file_pattern = "{rails,sapience}/.resultset.json"
    json_files = Dir[File.join(coverage_dir, coverage_file_pattern)]

    merged_hash = {}
    json_files.each do |json_file|
      content = File.read(json_file)
      content.gsub!(%r{\/usr\/src\/app}, Dir.pwd) # not inside docker anymore
      JSON.parse(content).each do |command_name, data|
        puts "#{json_file} –> '#{command_name}'"
        merged_hash = SimpleCov::Result.from_hash(command_name => data).original_result.merge_resultset(merged_hash)
      end
    end

    merged_result = SimpleCov::Result.new(merged_hash)
    result_file = File.join(coverage_dir, ".resultset.json")
    FileUtils.rm result_file if File.exist?(result_file)
    File.write(result_file, merged_result.to_hash.to_json)

    SimpleCov.coverage_dir coverage_dir
    [SimpleCov::Formatter::JSONFormatter, SimpleCov::Formatter::HTMLFormatter].each do |formatter|
      formatter.new.format(merged_result)
    end

    unhide_coverage_config
  end

  task :send do
    hide_coverage_config
    require "json"
    require "codeclimate-test-reporter"
    CodeClimate::TestReporter.configure do |config|
      config.branch = "master"
    end

    require "code_climate/test_reporter/ci" if ENV["CI"]
    ENV["CODECLIMATE_REPO_TOKEN"] = "204dc055302da6aed94379e249aa0645636d1d1794920c62db05c5fa968215de"
    resultset_file   = File.join(coverage_dir, ".resultset.json")
    result_hash      = JSON.parse(File.read(resultset_file))
    simplecov_result = SimpleCov::Result.from_hash(result_hash)

    CodeClimate::TestReporter::Formatter.new.format(simplecov_result)
    unhide_coverage_config
  end
end
