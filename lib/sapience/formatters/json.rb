# frozen_string_literal: true
require "json"
module Sapience
  module Formatters
    class Json < Raw
      # Default JSON time format is ISO8601
      def initialize(options = {})
        options               = options.dup
        options[:time_format] = :iso_8601 unless options.key?(:time_format)
        super(options)
      end

      # Returns log messages in JSON format
      def call(log, logger)
        h = super(log, logger)
        h.delete(:time)
        h[:timestamp] = format_time(log.time)
        h.to_json
      end
    end
  end
end
