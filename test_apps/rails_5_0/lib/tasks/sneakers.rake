# frozen_string_literal: true
require "sneakers/runner"

task :environment

namespace :sneakers do
  desc "Start processing jobs with all workers"
  task work: :environment do
    silence_warnings do
      Rails.application.eager_load! unless Rails.application.config.eager_load
    end

    workers = ApplicationJob.subclasses.map do |klass|
      klass.const_set("Wrapper", Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
        from_queue klass.queue_name
      end)
    end


    Sneakers::Runner.new(workers).run
  end
end
