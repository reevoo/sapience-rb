module Sapience
  class ErrorHandler
    class Silent < Sapience::ErrorHandler

      #   level: [:trace | :debug | :info | :warn | :error | :fatal]
      #    Override the log level for this appender.
      #    Default: Sapience.config.default_level
      #
      #   dsn: [String]
      #     Url to configure Sentry-Raven.
      #     Default: nil
      def initialize(_options = {})
        Sapience.logger.warn "Error handler is not configured. See documentation for more information."
      end

      def capture_exception(_exception, _payload = {})
        nil
      end

      def capture_message(_message, _payload = {})
        nil
      end

      def capture(_options: {})
        nil
      end
      alias_method :capture!, :capture

      def user_context(_options = {})
        nil
      end

      def tags_context(_options = {})
        nil
      end
    end
  end
end
