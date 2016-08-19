require "sapience"

module Sapience
  class Rails < ::Rails::Engine

    # Replace Rails logger initializer
    ::Rails::Application::Bootstrap.initializers.delete_if { |i| i.name == :initialize_logger }

    initializer :initialize_logger, group: :all do
      Sapience.configure
      ::Rails.logger = Sapience[::Rails]
      [:active_record, :action_controller, :action_mailer, :action_view].each do |name|
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

      # Replace the Sidetiq logger
      Sidetiq.logger              = Sapience[Sidetiq] if defined?(Sidetiq)

      # Replace the Raven logger
      # Raven::Configuration.logger = Sapience[Raven::Configuration] if defined?(Raven::Configuration)
      Raven.send(:include) { Sapience::Loggable }

      # Replace the Sneakers logger
      Sneakers.logger             = Sapience[Sneakers] if defined?(Sneakers)

      # Replace the Bugsnag logger
      Bugsnag.configure { |config| config.logger = Sapience[Bugsnag] } if defined?(Bugsnag)

      # Set the logger for concurrent-ruby
      Concurrent.global_logger = Sapience[Concurrent] if defined?(Concurrent)

      # Rails Patches
      Kernel.require "sapience/extensions/action_cable/tagged_logger_proxy" if defined?(ActionCable)
      Kernel.require "sapience/extensions/action_controller/live" if defined?(ActionController::Live)
      Kernel.require "sapience/extensions/action_dispatch/debug_exceptions" if defined?(ActionDispatch::DebugExceptions)
      if defined?(ActionView::StreamingTemplateRenderer::Body)
        Kernel.require "sapience/extensions/action_view/streaming_template_renderer"
      end
      Kernel.require "sapience/extensions/active_job/logging" if defined?(ActiveJob)
      Kernel.require "sapience/extensions/active_model_serializers/logging" if defined?(ActiveModelSerializers)
      Kernel.require "sapience/extensions/action_controller/log_subscriber" if defined?(ActionController)
      Kernel.require "sapience/extensions/active_record/log_subscriber" if defined?(ActiveRecord::LogSubscriber)
      Kernel.require "sapience/extensions/rails/rack/logger" if defined?(::Rails::Rack::Logger)
      Kernel.require "sapience/extensions/rails/rack/logger_info_as_debug" if defined?(::Rails::Rack::Logger)
      Kernel.require "sapience/extensions/action_view/log_subscriber" if defined?(ActionView::LogSubscriber)
      if defined?(ActionView::LogSubscriber)
        Kernel.require "sapience/extensions/action_controller/log_subscriber_processing"
      end
    end

    # Before any initializers run, but after the gems have been loaded
    config.after_initialize do
      # Replace the Bugsnag logger
      Bugsnag.configure { |config| config.logger = Sapience[Bugsnag] } if defined?(Bugsnag)
    end

  end
end
