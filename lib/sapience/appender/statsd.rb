require "uri"
begin
  require "statsd-ruby"
rescue LoadError
  raise 'Gem statsd-ruby is required for logging metrics. Please add the gem "statsd-ruby" to your Gemfile.'
end

# Example:
#   Sapience.add_appender(appender: :statsd)
#
class Sapience::Appender::Statsd < Sapience::Subscriber
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
  def initialize(options = {}, &block)
    options         = options.is_a?(Hash) ? options.dup : { level: options }
    @url    = options.delete(:url) || "udp://localhost:8125"
    options[:level] ||= :error
    fail('Statsd only supports udp. Example: "udp://localhost:8125"') if uri.scheme != "udp"

    @statsd           = ::Statsd.new(uri.host, uri.port)
    path              = uri.path.chomp("/")
    @statsd.namespace = path.sub("/", "") if path != ""

    super(options, &block)
  end

  # Send an error notification to sentry
  def log(log)
    metric = log.metric
    return false unless metric

    if duration = log.duration
      @statsd.timing(metric, duration)
    else
      amount = (log.metric_amount || 1).round
      if amount < 0
        amount.times { @statsd.decrement(metric) }
      else
        amount.times { @statsd.increment(metric) }
      end
    end
    true
  end
end
