# frozen_string_literal: true
require_relative "request_format_helper"

module Sapience
  module Extensions
    module Grape
      class Notifications < ::Sapience::Extensions::Notifications
        include RequestFormatHelper
        # Options:
        #
        # *<tt>:metric_name</tt> - the metric name, defaults to "grape.request"
        # *<tt>:tags</tt> - additional tags
        def initialize(opts = {})
          super
          @metric_name = opts[:metric_name] || "grape.request"

          Sapience::Extensions::Notifications.subscribe "endpoint_run.grape" do |event|
            record event
          end
        end

        private

        def record(event) # rubocop:disable AbcSize
          return unless record?

          payload  = event.payload
          endpoint = payload[:endpoint]
          route    = endpoint.route
          version  = route.version
          method   = route.request_method.downcase
          format   = request_format(endpoint.env)
          path = route.pattern.path.dup

          path.sub!(/\(\.#{format}\)$/, "")
          path.sub!(":version/", "") if version
          path.gsub!(/:(\w+)/) { |m| m[1..-1].upcase }
          path.gsub!(/[^\w\/\-]+/, "_")

          tags = self.tags + %W(method:#{method} format:#{format} path:#{path} status:#{endpoint.status})
          tags.push "version:#{version}" if version
          metrics.batch do
            metrics.increment metric_name, tags: tags
            metrics.timing "#{metric_name}.time", event.duration, tags: tags
          end
        end
      end
    end
  end
end
