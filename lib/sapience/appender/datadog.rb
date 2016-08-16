require "uri"
begin
  require "statsd"
rescue LoadError
  raise 'Gem dogstatsd-ruby is required for logging metrics. Please add the gem "dogstatsd-ruby" to your Gemfile.'
end

# Example:
#   Sapience.add_appender(:datadog, {url: "udp://localhost:2222"})
#
module Sapience
  module Appender
    class Datadog < Sapience::Subscriber
      # Create Appender
      #
      # Parameters:
      #   level: :trace
      #   url: [String]
      #     Valid URL to post to.
      #     Example:
      #       udp://localhost:8125
      #     Example, send all metrics to a particular namespace:
      #       udp://localhost:8125/namespace
      #     Default: udp://localhost:8125
      #   tags: [String]
      #     Example:
      #       tag1:true
      # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity

      def initialize(options = {}, &block)
        fail('Options should be a Hash') unless options.is_a?(Hash)
        url   = options.delete(:url) || "udp://localhost:8125"
        @tags = options.delete(:tags)
        @uri  = URI.parse(url)
        fail('Statsd only supports udp. Example: "udp://localhost:8125"') if @uri.scheme != "udp"

        super(options, &block)
      end

      def provider
        @_provider ||= begin
          statsd           = ::Statsd.new(@uri.host, @uri.port, tags: @tags)
          path             = @uri.path.chomp("/")
          statsd.namespace = path.sub("/", "") if path != ""
          statsd
        end
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
        provider.timing(metric, duration)
      end

      def increment(metric, amount)
        provider.batch do
          amount.times { provider.increment(metric) }
        end
      end

      def decrement(metric, amount)
        provider.batch do
          amount.abs.times { provider.decrement(metric) }
        end
      end

      def histogram(metric, amount)
        provider.histogram(metric, amount)
      end

    end
  end
end
