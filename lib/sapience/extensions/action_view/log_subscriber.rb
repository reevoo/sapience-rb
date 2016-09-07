require "action_view/log_subscriber"

module Sapience
  module Extensions
    module ActionView
      class LogSubscriber < ::ActionView::LogSubscriber
        include Sapience::Loggable

        def info(message = nil, &block)
          logger.debug(message, &block)
        end

        def info?
          logger.debug?
        end

      end
    end
  end
end
