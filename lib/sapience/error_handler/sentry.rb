begin
  require "sentry-raven"
rescue LoadError
  raise 'Gem sentry-raven is required for logging purposes. Please add the gem "sentry-raven" to your Gemfile.'
end

# Send log messages to sentry
#
# Example:
#   Sapience.add_appender(:stream, {io: STDOUT, formatter: :color})
#
# rubocop:disable Style/ClassAndModuleChildren
module Sapience
  class ErrorHandler
    class Sentry < Sapience::ErrorHandler
      VALIDATION_MESSAGE = "DSN is not valid, please add appender with :dsn key or set SENTRY_DSN".freeze
      URI_REGEXP = URI::DEFAULT_PARSER.regexp[:ABS_URI]
      #
      #   level: [:trace | :debug | :info | :warn | :error | :fatal]
      #    Override the log level for this appender.
      #    Default: Sapience.config.default_level
      #
      #   dsn: [String]
      #     Url to configure Sentry-Raven.
      #     Default: nil
      def initialize(options = {})
        fail ArgumentError, "Options should be a Hash" unless options.is_a?(Hash)

        options[:level] ||= :error
        @sentry_logger_level = options[:level]
        @sentry_dsn = options.delete(:dsn)
        @configured = false
      end

      def valid?
        sentry_dsn =~ URI_REGEXP
      end

      def capture_exception(exception, payload = {})
        capture_type(exception, payload)
      end

      def capture_message(message, payload = {})
        capture_type(message, payload)
      end

      def user_context(options = {})
        Raven.user_context(options)
      end

      def tags_context(options = {})
        Raven.tags_context(options)
      end
      alias_method :tags=, :tags_context

      def configured?
        @configured == true
      end

      def configure_sentry
        return if configured?
        Raven.configure do |config|
          config.server = sentry_dsn
          config.tags   = { environment: Sapience.environment }
          config.logger = sentry_logger
        end
        @configured = true
      end

      # Capture, process and reraise any exceptions from the given block.
      #
      # @example
      #   Raven.capture do
      #     MyApp.run
      #   end
      def capture!(options = {})
        fail ArgumentError unless block_given?

        begin
          yield
        rescue StandardError => e
          capture_type(e, options)
          raise
        end
      end

      # Capture, process and not reraise any exceptions from the given block.
      #
      # @example
      #   Raven.capture do
      #     MyApp.run
      #   end
      def capture(options = {})
        fail ArgumentError unless block_given?

        begin
          yield
        rescue StandardError => e
          capture_type(e, options)
        end
      end

      private

      def capture_type(data, payload)
        return false unless valid?
        configure_sentry

        options = payload[:extra] ? payload : { extra: payload }

        Raven.capture_type(data, options) if @configured
      rescue Exception => ex # rubocop:disable RescueException
        Sapience.logger.error("Raven.capture_type failed with", payload, ex)
      end

      def sentry_dsn
        (@sentry_dsn || ENV["SENTRY_DSN"]).to_s
      end


      # Sapience logger
      def sentry_logger
        @sentry_logger ||= begin
          logger = Sapience[self.class]
          logger.level = @sentry_logger_level
          logger
        end
      end
    end
  end
end
