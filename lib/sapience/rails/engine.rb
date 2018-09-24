# frozen_string_literal: true
require "sapience"
require "sapience/extensions/action_controller/live" if defined?(ActionController::Live)
require "sapience/extensions/action_controller/log_subscriber"
require "sapience/extensions/action_controller/notifications"
require "sapience/extensions/action_dispatch/debug_exceptions"
require "sapience/extensions/action_view/streaming_template_renderer"
if defined?(ActiveRecord)
  require "sapience/extensions/active_record/log_subscriber"
  require "sapience/extensions/active_record/notifications"
end
require "sapience/extensions/active_job/notifications" if defined?(ActiveJob)
require "sapience/extensions/rails/rack/logger"
require "sapience/extensions/rails/rack/logger_info_as_debug"
require "sapience/extensions/action_view/log_subscriber"
require "sapience/loggers/concurrent"

module Sapience
  module Rails
    class Engine < ::Rails::Engine
      # Replace Rails logger initializer
      ::Rails::Application::Bootstrap.initializers.delete_if { |i| i.name == :initialize_logger }

      initializer :initialize_logger, group: :all, before: :bootstrap_hook do
        Sapience.configure

        %i[active_record action_controller action_mailer action_view].each do |name|
          ActiveSupport.on_load(name) { include Sapience::Loggable }
        end
        ActiveSupport.on_load(:action_cable) { self.logger = Sapience["ActionCable"] }
      end

      # Before any initializers run, but after the gems have been loaded
      config.before_initialize do
        # Replace the Mongoid Logger
        Mongoid.logger              = Sapience[Mongoid] if defined?(Mongoid)
        Moped.logger                = Sapience[Moped] if defined?(Moped)

        # Replace the Resque Logger
        Resque.logger               = Sapience[Resque] if defined?(Resque) && Resque.respond_to?(:logger)

        # Replace the Sidekiq logger
        Sidekiq::Logging.logger     = Sapience[Sidekiq] if defined?(Sidekiq)

        # Replace the Sequel logger
        Sequel::Database.logger     = Sapience[Sequel] if defined?(Sequel::Database)

        # Replace the Sidetiq logger
        Sidetiq.logger              = Sapience[Sidetiq] if defined?(Sidetiq)

        # Replace the Raven logger
        # Raven::Configuration.logger = Sapience[Raven::Configuration] if defined?(Raven::Configuration)
        Raven.send(:include, Sapience::Loggable)

        # Replace the Sneakers logger
        Sneakers.configure(log: Sapience[Sneakers]) if defined?(Sneakers)

        # Replace the Bugsnag logger
        Bugsnag.configure { |config| config.logger = Sapience[Bugsnag] } if defined?(Bugsnag)

        # Set the logger for concurrent-ruby
        Concurrent.global_logger = Sapience::Loggers::Concurrent.new if defined?(Concurrent)
      end

      # Before any initializers run, but after the gems have been loaded
      config.after_initialize do
        # in the rare case a gem disables logging but still requires a logger (teaspoon gem)
        ::Rails.logger ||= Sapience[::Rails]

        require "sapience/extensions/action_cable/tagged_logger_proxy" if defined?(ActionCable)
        require "sapience/extensions/active_model_serializers/logging" if defined?(ActiveModelSerializers)
        require "sapience/extensions/active_job/logging" if defined?(ActiveJob)
        # Replace the Bugsnag logger
        Bugsnag.configure { |config| config.logger = Sapience[Bugsnag] } if defined?(Bugsnag)
        Sapience::Extensions::ActionController::LogSubscriber.attach_to :action_controller
        # Sapience::Extensions::ActiveSupport::MailerLogSubscriber.attach_to :action_mailer
        Sapience::Extensions::ActiveRecord::Notifications.use if defined?(ActiveRecord)
        Sapience::Extensions::ActionView::LogSubscriber.attach_to :action_view
        # Sapience::Extensions::ActiveJob::LogSubscriber.attach_to :active_job
        Sapience::Extensions::ActionController::Notifications.use
        Sapience::Extensions::ActiveJob::Notifications.use if defined?(ActiveJob)
      end
    end
  end
end
