begin
  require "sentry-raven"
rescue LoadError
  raise 'Gem sentry-raven is required for logging purposes. Please add the gem "sentry-raven" to your Gemfile.'
end

# Send log messages to sentry
#
# Example:
#   Sapience.add_appender(:sentry, {})
#
# rubocop:disable Style/ClassAndModuleChildren
module Sapience
  module Appender
    class Sentry < Sapience::Subscriber
      # Create Appender
      #
      # Parameters
      #   level: [:trace | :debug | :info | :warn | :error | :fatal]
      #     Override the log level for this appender.
      #     Default: :error
      #
      #   formatter: [Object|Proc|Symbol|Hash]
      #     An instance of a class that implements #call, or a Proc to be used to format
      #     the output from this appender
      #     Default: Use the built-in formatter (See: #call)
      #
      #   filter: [Regexp|Proc]
      #     RegExp: Only include log messages where the class name matches the supplied.
      #     regular expression. All other messages will be ignored.
      #     Proc: Only include log messages where the supplied Proc returns true
      #           The Proc must return true or false.
      #
      #   host: [String]
      #     Name of this host to appear in log messages.
      #     Default: Sapience.config.host
      #
      #   application: [String]
      #     Name of this application to appear in log messages.
      #     Default: Sapience.config.application
      def initialize(options = {}, &block)
        validate_options!(options)

        options[:level] ||= :error
        Raven.configure do |config|
          config.dsn  = options.delete(:dsn)
          config.tags = { environment: Sapience.environment }
        end

        super(options, &block)
      end

      def validate_options!(options = {})
        fail ArgumentError, "Options should be a Hash" unless options.is_a?(Hash)
        dsn_valid = options[:dsn].to_s =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
        fail ArgumentError, "The :dsn key (#{options[:dsn]}) is not a valid URI" unless dsn_valid
      end

      # Send an error notification to sentry
      def log(log)
        return false unless should_log?(log)

        context = formatter.call(log, self)
        if log.exception
          context.delete(:exception)
          Raven.capture_exception(log.exception, context)
        else
          message = {
            error_class:   context.delete(:name),
            error_message: context.delete(:message),
            context: context,
          }
          message[:backtrace] = log.backtrace if log.backtrace
          Raven.capture_message(message[:error_message], message)
        end
        true
      end

      private

      # Use Raw Formatter by default
      def default_formatter
        Sapience::Formatters::Raw.new
      end
    end
  end
end
