COVERAGE_FILE = ".simplecov".freeze
COVERAGE_BKP_FILE = ".simplecov.bkp".freeze
COVERAGE_DIR = "./coverage".freeze

def hide_coverage_config
  FileUtils.mv COVERAGE_FILE, COVERAGE_BKP_FILE
rescue Errno::ENOENT => ex
  p ex.message, ex.backtrace
end

def unhide_coverage_config
  FileUtils.mv COVERAGE_BKP_FILE, COVERAGE_FILE
rescue Errno::ENOENT => ex
  p ex.message, ex.backtrace
end

namespace :coverage do
  task :merge do
    hide_coverage_config
    require "json"
    require "simplecov/version"
    require "simplecov/result"
    require "simplecov-html"
    require "simplecov-json"

    require "pry-nav"
    coverage_file_pattern = "{rails,sapience}/.resultset.json"
    json_files = Dir[File.join(COVERAGE_DIR, coverage_file_pattern)]

    merged_hash = {}
    json_files.each do |json_file|
      JSON.parse(File.read(json_file)).each do |command_name, data|
        puts "#{json_file} –> '#{command_name}'"
        merged_hash = SimpleCov::Result.from_hash(command_name => data).original_result.merge_resultset(merged_hash)
      end
    end

    merged_result = SimpleCov::Result.new(merged_hash)
    result_file = File.join(COVERAGE_DIR, ".resultset.json")
    FileUtils.rm result_file
    File.open(result_file, "w") do |file|
      file.puts merged_result.to_hash.to_json
    end

    SimpleCov.coverage_dir COVERAGE_DIR
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
    resultset_file   = File.join(COVERAGE_DIR, ".resultset.json")
    result_hash      = JSON.parse(File.read(resultset_file))
    simplecov_result = SimpleCov::Result.from_hash(result_hash)

    CodeClimate::TestReporter::Formatter.new.format(simplecov_result)
    unhide_coverage_config
  end
end
