module Sapience
  module Extensions
    class Notifications
      attr_reader :tags, :metric_name

      def self.subscribe(pattern, &block)
        ActiveSupport::Notifications.subscribe(pattern) do |*args|
          block.call ActiveSupport::Notifications::Event.new(*args)
        end
      end

      def initialize(options = {})
        @tags = options[:tags] || []
      end

      def record?
        !metrics.nil?
      end

      def metrics
        Sapience.metrics
      end
    end
  end
end
