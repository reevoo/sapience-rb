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
        prepare(h, log).to_json
      end

      private

      def prepare(log_hash, log)
        set_timestamp(log_hash, log)
        remove_fields(log_hash)
        log_hash
      end

      def set_timestamp(log_hash, log)
        log_hash.delete(:time)
        log_hash[:timestamp] = format_time(log.time)
        log_hash
      end

      def remove_fields(log_hash)
        log_hash.delete_if { |k, _v| exclude_fields.include?(k.to_sym) } if exclude_fields.any?
      end
    end
  end
end
