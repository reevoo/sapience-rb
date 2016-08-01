require "sapience/version"
require "ostruct"
require "semantic_logger"

module Sapience
  DEFAULT_CONFIGURATION ||= {
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
  }.freeze

  class << self
    attr_accessor :configuration

    def reset_configuration!
      self.configuration = DEFAULT_CONFIGURATION.dup
    end

    def configure
      yield configuration

      configure_logger
    end

    def default_level=(level)
      SemanticLogger.default_level = level
    end

    def configure_logger
      self.default_level = configuration[:logger][:default_level]

      configuration[:logger][:appenders].each do |appender|
        add_appender(appender)
      end

      SemanticLogger.on_metric(metrics_subscriber) if log_metrics?
    end

    def metrics_subscriber
      @metrics_subscriber ||= SemanticLogger::Metrics::Statsd.new(configuration[:metrics])
    end

    def log_metrics?
      !metrics_subscriber.nil?
    end

    def add_appender(options = {})
      SemanticLogger.add_appender(options)
    end
  end

  reset_configuration!
end

require "sapience/loggable"
