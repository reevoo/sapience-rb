# frozen_string_literal: true
require "json"
require "ddtrace"

module Sapience
  module Formatters
    class Datadog < Json

      def to_json(hash)
        correlation = ::Datadog.tracer.active_correlation
        hash[:dd] = {span_id:  correlation.span_id.to_s, trace_id: correlation.trace_id.to_s }
        hash.to_json
      end
    end
  end
end
