module Sapience
  module Extensions
    module ActiveJob
      class Notifications < ::Sapience::Extensions::Notifications

        # Options:
        #
        # *<tt>:metric_name</tt> - the metric name, defaults to "activejob.perform"
        # *<tt>:tags</tt>        - additional tags
        def initialize(opts = {})
          super
          @metric_name = opts[:metric_name] || "activejob.perform"

          Sapience::Extensions::Notifications.subscribe "perform.active_job" do |event|
            record event
          end
        end

        private

        def record(event) # rubocop:disable AbcSize
          return unless record?

          job  = event.payload[:job]
          name = job.class.name.sub(/Job$/, "").underscore
          tags = self.tags + %W(name:#{name} queue:#{job.queue_name})
          metrics.batch do
            metrics.increment metric_name, tags: tags
            metrics.timing "#{metric_name}.time", event.duration, tags: tags
          end
        end
      end
    end
  end
end
