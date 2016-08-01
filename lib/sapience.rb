require "sapience/version"
require "ostruct"
require "semantic_logger"

module Sapience
  def self.configuration
    @configuration ||= {
      logger: {
        default_level: :trace,
        appenders: [
          { io: STDOUT, formatter: :json },
          { appender: :sentry },
        ],
      },
      metrics: {
        url: "udp://localhost:8125",
      },
    }
  end

  def self.configure
    yield configuration

    configure_logger
  end

  def self.default_level=(level)
    SemanticLogger.default_level = level
  end

  def self.configure_logger
    self.default_level = configuration[:logging][:default_level]

    configuration[:logging][:appenders].each do |appender|
      add_appender(appender)
    end

    SemanticLogger.on_metric(metrics_subscriber) if metrics_subscriber
  end

  def self.metrics_subscriber
    @metrics_subscriber ||= SemanticLogger::Metrics::Statsd.new(configuration.metrics.slice(:url))
  end

  def self.log_metrics?
    @metrics_subscriber ||= SemanticLogger::Metrics::Statsd.new(configuration.metrics.slice(:url))
  end

  def self.add_appender(options = {})
    SemanticLogger.add_appender(options)
  end
end

require "sapience/loggable"
