 require "sapience/version"
require "ostruct"
require "semantic_logger"

module Sapience
  DEFAULT_CONFIGURATION ||= {
    logger: {
      application: "Sapience Application",
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
      yield configuration if block_given?

      configure_logger
    end

    def default_level=(level)
      SemanticLogger.default_level = level
    end

    def application=(name)
      SemanticLogger.application = name
    end

    def logger(name)
      SemanticLogger[name]
    end

    def configure_logger
      add_logger_defaults
      add_logger_appenders
      SemanticLogger.on_metric(metrics_subscriber) if log_metrics?
    end

    def add_logger_defaults
      self.default_level = configuration[:logger][:default_level]
      self.application   = configuration[:logger][:application]
    end

    def add_logger_appenders
      SemanticLogger.appenders.each do |appender|
        SemanticLogger.remove_appender(appender)
      end
      configuration[:logger][:appenders].try(:each) do |appender|
        add_appender(appender)
      end
    end

    def metrics_subscriber
      @metrics_subscriber ||= SemanticLogger::Metrics::Statsd.new(configuration[:metrics])
    end

    def log_metrics?
      configuration[:metrics] && !metrics_subscriber.nil?
    end

    def add_appender(options = {})
      SemanticLogger.add_appender(options)
    end
  end

  reset_configuration!
end

require "sapience/loggable"
