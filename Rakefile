# frozen_string_literal: true
require "bundler/gem_tasks"
require "rspec/core/rake_task"
load "lib/tasks/coverage.rake"

RSpec::Core::RakeTask.new(:spec)

begin
  require "reevoocop/rake_task"
  ReevooCop::RakeTask.new(:reevoocop) do |task|
    task.options = ["-D"]
  end
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

task default: [:spec]
