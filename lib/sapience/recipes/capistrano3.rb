# encoding: utf-8

begin
  require 'capistrano/framework'

  namespace :sapience do
    # notifies pre-configured metrics system of a deployment
    desc "Record a deployment event"
    task :deploy_notification do
      run_locally do
        begin
          # allow overrides to be defined for revision, description, changelog, appname, and user
          revision = fetch(:current_revision)
          event_key = "#{Sapience.metrics.namespace}.deploy"
          event_message = revision

          Sapience.metrics.event(event_key, event_message, aggregation_key: event_key)
        rescue => e
          info "Error creating deployment notification event (#{e})\n#{e.backtrace.join("\n")}"
        end
      end
    end
  end
rescue LoadError
  warn 'Capistrano deploy notification recipe is not available. Please add this gem to your Gemfile.'
end

