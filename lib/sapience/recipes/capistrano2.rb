# encoding: utf-8

begin

  require 'pry'
  binding.pry

  make_notify_task = Proc.new do
    namespace :sapience do
      # notifies pre-configured metrics system of a deployment
      desc "Record a deployment event"
      task deploy_notification: :environment do
        run_locally do
          begin
            # allow overrides to be defined for revision, description, changelog, appname, and user
            revision      = fetch(:current_revision)
            event_key     = "#{Sapience.metrics.namespace}.deploy"
            event_message = revision

            Sapience.metrics.event(event_key, event_message, aggregation_key: event_key)
          rescue => e
            info "Error creating deployment notification event (#{e})\n#{e.backtrace.join("\n")}"
          end
        end
      end
    end
  end

  if defined?(Capistrano::Version::MAJOR) && Capistrano::Version::MAJOR < 2
    STDERR.puts "Unable to load #{__FILE__}\nSapience Capistrano hooks require at least version 2.0.0"
  else
    instance = Capistrano::Configuration.instance

    if instance
      instance.load(&make_notify_task)
    else
      make_notify_task.call
    end
  end
rescue LoadError => ex
  warn 'WARNING!!! Capistrano deploy notification recipe is not available. Please add this gem to your Gemfile.'
end

