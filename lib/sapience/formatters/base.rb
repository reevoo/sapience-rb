# frozen_string_literal: true
module Sapience
  module Formatters
    class Base
      attr_accessor :time_format, :default_time_format, :precision, :log_host, :log_application, :exclude_fields

      # Parameters
      #   time_format: [String|Symbol|nil]
      #     See Time#strftime for the format of this string
      #     :iso_8601 Outputs an ISO8601 Formatted timestamp
      #     nil:      Returns Empty string for time ( no time is output ).
      #     Default: '%Y-%m-%d %H:%M:%S.%6N'
      def initialize(options = {})
        @precision           = 6
        @default_time_format = "%Y-%m-%d %H:%M:%S.%#{precision}N"
        parse_options(options.dup)
      end

      # Return the Time as a formatted string
      def format_time(time)
        case time_format
        when :iso_8601
          time.utc.iso8601(precision)
        when nil
          ""
        else
          time.strftime(time_format)
        end
      end

      private

      def parse_options(options)
        @time_format     = options.key?(:time_format) ? options.delete(:time_format) : default_time_format
        @log_host        = options.key?(:log_host) ? options.delete(:log_host) : true
        @log_application = options.key?(:log_application) ? options.delete(:log_application) : true
        @exclude_fields  = options.key?(:exclude_fields) ? options.delete(:exclude_fields).map(&:to_sym) : {}
        fail(ArgumentError, "Unknown options: #{options.inspect}") unless options.empty?
      end
    end
  end
end
