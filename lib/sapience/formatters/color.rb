# frozen_string_literal: true
# Load AwesomePrint if available
begin
  require "awesome_print"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

module Sapience
  module Formatters
    class Color < Base
      # Parameters:
      #   ap: Any valid AwesomePrint option for rendering data.
      #       These options can also be changed be creating a `~/.aprc` file.
      #       See: https://github.com/michaeldv/awesome_print
      #
      #       Note: The option :multiline is set to false if not supplied.
      #       Note: Has no effect if Awesome Print is not installed.
      def initialize(options = {})
        options     = options.dup
        @ai_options = options.delete(:ap) || { multiline: false }
        super(options)
      end

      # Adds color to the default log formatter
      # Example:
      #   Sapience.add_appender(:stream, io: $stdout, formatter: :color)
      def call(log, _logger) # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity
        colors      = Sapience::AnsiColors
        level_color = colors::LEVEL_MAP[log.level]


        message = time_format.nil? ? "" : "#{format_time(log.time)} "

        # Header with date, time, log level and process info
        message += "#{level_color}#{log.level_to_s}#{colors::CLEAR} [#{log.process_info}]"

        # Tags
        message += " " + log.tags.collect { |tag| "[#{level_color}#{tag}#{colors::CLEAR}]" }.join(" ") if log.tags && !log.tags.empty? # rubocop:disable LineLength

        # Duration
        message += " (#{colors::BOLD}#{log.duration_human}#{colors::CLEAR})" if log.duration

        # Class / app name
        message += " #{level_color}#{log.name}#{colors::CLEAR}"

        # Log message
        message += " -- #{log.message}" if log.message

        # Payload: Colorize the payload if the AwesomePrint gem is loaded
        if log.payload?
          payload = log.payload
          message += " -- "
          message += if defined?(AwesomePrint) && payload.respond_to?(:ai)
                       payload.ai(@ai_options) rescue payload.inspect # rubocop:disable RescueModifier
                     else
                       payload.inspect
                     end
        end

        # Exceptions
        if log.exception
          message += " -- Exception: #{colors::BOLD}#{log.exception.class}: #{log.exception.message}#{colors::CLEAR}\n"
          message += log.backtrace_to_s
        end
        message
      end
    end
  end
end
