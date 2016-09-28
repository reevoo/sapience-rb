require "uri"
begin
  require "datadog/statsd"
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
        fail("Options should be a Hash") unless options.is_a?(Hash)
        url   = options.delete(:url) || "udp://localhost:8125"
        @tags = options.delete(:tags)
        @uri  = URI.parse(url)
        fail('Statsd only supports udp. Example: "udp://localhost:8125"') if @uri.scheme != "udp"

        super(options, &block)
      end

      def provider
        @_provider ||= ::Datadog::Statsd.new(@uri.host, @uri.port, dog_options)
      end

      # Send an error notification to sentry
      def log(log)
        metric = log.metric
        return false unless metric

        if log.duration
          timing(metric, log.duration, tags: log.tags)
        else
          amount = (log.metric_amount || 1).round
          count(metric, amount, tags: log.tags)
        end
        true
      end

      def timing(metric, duration = 0, options = {})
        if block_given?
          start = Time.now
          yield
          provider.timing(metric, ((Time.now - start) * 1000).floor, options)
        else
          provider.timing(metric, duration, options)
        end
      end

      def increment(metric, options = {})
        provider.increment(metric, options)
      end

      def decrement(metric, options = {})
        provider.decrement(metric, options)
      end

      def histogram(metric, amount, options = {})
        provider.histogram(metric, amount, options)
      end

      def gauge(metric, amount, options = {})
        provider.gauge(metric, amount, options)
      end

      def count(metric, amount, options = {})
        provider.count(metric, amount, options)
      end

      def time(metric, options = {}, &block)
        provider.time(metric, options, &block)
      end

      def batch(&block)
        provider.batch(&block)
      end

      def event(title, text, options = {})
        provider.event(title, text, options)
      end

      def namespace
        ns = Sapience.namify(Sapience.app_name)
        ns << ".#{Sapience.namify(Sapience.environment)}" if Sapience.environment
        ns
      end

      def dog_options
        {
          namespace: namespace,
          tags: @tags,
        }
      end
    end
  end
end
