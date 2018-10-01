# frozen_string_literal: true
module Sapience
  module Extensions
    module ActionController
      class Notifications < ::Sapience::Extensions::Notifications
        # Options:
        #
        # *<tt>:metric_name</tt> - the metric name, defaults to "rails.request"
        # *<tt>:tags</tt> - additional tags
        def initialize(options = {})
          @metric_name = options[:metric_name] || "rails.request"
          super
          Sapience::Extensions::Notifications.subscribe("process_action.action_controller") do |event|
            record event
          end
        end

        private

        def record(event) # rubocop:disable AbcSize
          return unless record?

          payload = event.payload
          method  = payload[:method].downcase
          status  = payload[:status]
          action  = payload[:action]
          ctrl    = payload[:controller].sub(/Controller$/, "").underscore
          format  = payload[:format]

          tags    = self.tags + %W(
            method:#{method}
            status:#{status}
            action:#{action}
            controller:#{ctrl}
            format:#{format}
          )

          metrics.batch do
            metrics.increment metric_name, tags: tags
            metrics.timing("#{metric_name}.time", event.duration, tags: tags)
            metrics.timing("#{metric_name}.time.db", payload[:db_runtime].round(10), tags: tags) if payload[:db_runtime]



            if payload[:view_runtime]
              metrics.timing("#{metric_name}.time.view", payload[:view_runtime].round(2), tags: tags)
            end
          end
        end
      end
    end
  end
end
