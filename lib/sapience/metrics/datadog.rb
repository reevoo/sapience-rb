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
  class Metrics
    class Datadog < Sapience::Metrics
      VALIDATION_MESSAGE = "Statsd only supports udp. Example: '#{Sapience::DEFAULT_STATSD_URL}'".freeze

      # Create Appender
      #
      # Parameters:
      #   level: :trace
      #   url: [String]
      #     Valid URL to postdogstatsd-ruby to.
      #     Example:
      #       udp://localhost:8125
      #     Example, send all metrics to a particular namespace:
      #       udp://localhost:8125/namespace
      #     Default: udp://localhost:8125
      #   tags: [String]
      #     Example:
      #       tag1:true
      # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity

      def initialize(options = {})
        fail("Options should be a Hash") unless options.is_a?(Hash)
        url   = options.delete(:url) || Sapience::DEFAULT_STATSD_URL
        @tags = options.delete(:tags)
        @uri  = URI.parse(url)
      end

      def provider
        @_provider ||= ::Datadog::Statsd.new(@uri.host, @uri.port, dog_options)
      end

      def valid?
        @uri.scheme == "udp"
      end

      def timing(metric, duration = 0, options = {})
        if block_given?
          start = Time.now
          yield
          return false unless valid?
          provider.timing(metric, ((Time.now - start) * 1000).floor, options)
        else
          return false unless valid?
          provider.timing(metric, duration, options)
        end
      end

      def increment(metric, options = {})
        return false unless valid?
        provider.increment(metric, options)
      end

      def decrement(metric, options = {})
        return false unless valid?
        provider.decrement(metric, options)
      end

      def histogram(metric, amount, options = {})
        return false unless valid?
        provider.histogram(metric, amount, options)
      end

      def gauge(metric, amount, options = {})
        return false unless valid?
        provider.gauge(metric, amount, options)
      end

      def count(metric, amount, options = {})
        return false unless valid?
        provider.count(metric, amount, options)
      end

      def time(metric, options = {}, &block)
        return false unless valid?
        provider.time(metric, options, &block)
      end

      def batch(&block)
        provider.batch(&block)
      end

      # Create Event
      #
      # @param [String] title the title of the event
      # @param [String] text  the description
      # @param [Hash] opts event options
      # @option opts [Array] :namespaced_keys the keys we want to be namespaced. Valid: :title or :aggregation_key
      # @option opts [String] :namespace_prefix custom namespace (to override default from Sapience `app_name.environment`)
      # @option opts [String] :aggregation_key custom aggregation_key (to override default based on `title`, only applies when :aggregation_key includes into namespaced_keys option)
      #
      # @example Create an Event
      #   Sapience.metrics.event('article-published', "article #123")
      #
      # @example Create a namespaced Event with default namespacing
      #   Sapience.metrics.event('article-published', "article #123", {namespaced_keys: [:title, :aggregation_key]})
      #
      # @example Create a namespaced Event with custom namespacing
      #   Sapience.metrics.event('article-published', "article #123", {namespace_prefix: 'custom_namespace',  namespaced_keys: [:title, :aggregation_key]})
      #
      # @example Create an Event with a custom aggregation_key
      #   Sapience.metrics.event('article-published', "article #123", {aggregation_key: 'custom_aggregation_key')

      def event(title, text = '', opts)
        return false unless valid?
        opts ||= {}
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
