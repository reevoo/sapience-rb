require "uri"
begin
  require "datadog"
rescue LoadError
  raise 'Gem statsd-ruby is required for logging metrics. Please add the gem "statsd-ruby" to your Gemfile.'
end

# Example:
#   Sapience.add_appender(:statsd, {url: "udp://localhost:2222"})
#
module Sapience
  module Appender
    class Datadog < Sapience::Appender::Statsd
      # Create Appender
      #
      # Parameters:
      #   url: [String]
      #     Valid URL to post to.
      #     Example:
      #       udp://localhost:8125
      #     Example, send all metrics to a particular namespace:
      #       udp://localhost:8125/namespace
      #     Default: udp://localhost:8125
      # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity
      def initialize(options = {}, &block)
        options = options.is_a?(Hash) ? options.dup : { level: options }
        url     = options.delete(:url) || "udp://localhost:8125"
        uri     = URI.parse(url)
        fail('Statsd only supports udp. Example: "udp://localhost:8125"') if uri.scheme != "udp"


        path              = uri.path.chomp("/")
        @statsd.namespace = path.sub("/", "") if path != ""

        super(options, &block)
      end

      def provider
        @_provider ||= ::Statsd.new(uri.host, uri.port)
      end

      # Send an error notification to sentry
      def log(log)
        metric = log.metric
        return false unless metric

        if log.duration
          timing(metric, log.duration)
        else
          amount = (log.metric_amount || 1).round
          if amount < 0
            decrement(metric, amount)
          else
            increment(metric, amount)
          end
        end
        true
      end

      def timing(metric, duration)
        @statsd.timing(metric, duration)
      end

      def increment(metric, amount)
        @statsd.batch do
          amount.times { @statsd.increment(metric) }
        end
      end

      def decrement(metric, amount)
        @statsd.batch do
          amount.abs.times { @statsd.decrement(metric) }
        end
      end
    end
  end
end
