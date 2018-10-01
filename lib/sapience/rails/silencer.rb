module Sapience
  module Rails
    module Silencer

      # remove all rails log subscribers. Copied from project https://github.com/roidrage/lograge
      def self.remove_log_subscriptions
        ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
          case subscriber
          when ActionView::LogSubscriber
            unsubscribe(:action_view, subscriber)
          when ActionController::LogSubscriber
            unsubscribe(:action_controller, subscriber)
          end
        end
      end

      def self.unsubscribe(component, subscriber)
        events = subscriber.public_methods(false).reject { |method| method.to_s == "call" }
        events.each do |event|
          ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
            if listener.instance_variable_get("@delegate") == subscriber
              ActiveSupport::Notifications.unsubscribe listener
            end
          end
        end
      end

    end
  end
end
