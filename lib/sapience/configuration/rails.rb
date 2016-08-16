module Sapience
  class Configuration
    class Rails
      # rubocop:disable LineLength, AbcSize, CyclomaticComplexity, PerceivedComplexity
      def self.configure
        ::Rails.logger = Sapience[::Rails]
        [:active_record, :action_controller, :action_mailer, :action_view].each do |name|
          ActiveSupport.on_load(name) { include Sapience::Loggable }
        end
        ActiveSupport.on_load(:action_cable) { self.logger = Sapience["ActionCable"] }
        require("sapience/extensions/action_cable/tagged_logger_proxy") if defined?(ActionCable)
        require("sapience/extensions/action_controller/live") if defined?(ActionController::Live)
        require("sapience/extensions/action_dispatch/debug_exceptions") if defined?(ActionDispatch::DebugExceptions)
        require("sapience/extensions/action_view/streaming_template_renderer") if defined?(ActionView::StreamingTemplateRenderer::Body)
        require("sapience/extensions/active_job/logging") if defined?(ActiveJob)
        require("sapience/extensions/active_model_serializers/logging") if defined?(ActiveModelSerializers)
        require("sapience/extensions/rack/logger") if defined?(Rails::Rack::Logger)
        require("sapience/extensions/action_controller/log_subscriber") if defined?(ActionController)
        require("sapience/extensions/active_record/log_subscriber") if defined?(ActiveRecord::LogSubscriber)
        require("sapience/extensions/rack/logger_info_as_debug") if defined?(Rails::Rack::Logger)
        require("sapience/extensions/action_view/log_subscriber") if defined?(ActionView::LogSubscriber)
        require("sapience/extensions/action_controller/log_subscriber_processing") if defined?(ActionView::LogSubscriber)
      end
      # rubocop:enable LineLength, AbcSize, CyclomaticComplexity, PerceivedComplexity
    end
  end
end
