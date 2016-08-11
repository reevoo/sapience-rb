require "ostruct"

module Sapience
  class Configuration
    attr_reader :default_level, :backtrace_level, :backtrace_level_index
    attr_writer :host
    attr_accessor :application, :ap_options, :appenders

    def initialize
      # Initial default Level for all new instances of Sapience::Logger
      self.default_level   = :info
      self.backtrace_level = :info
      self.application     = "Sapience"
      self.host            = nil
      self.ap_options      = { multiline: false }
      self.appenders       = { file: { io: STDOUT, formatter: :color } }
    end

    # Sets the global default log level
    def default_level=(level)
      @default_level       = level
      # For performance reasons pre-calculate the level index
      @default_level_index = level_to_index(level)
    end

    # Returns the symbolic level for the supplied level index
    def index_to_level(level_index)
      LEVELS[level_index]
    end

    # Internal method to return the log level as an internal index
    # Also supports mapping the ::Logger levels to Sapience levels
    def level_to_index(level)
      return if level.nil?

      index =
        if level.is_a?(Symbol)
          LEVELS.index(level)
        elsif level.is_a?(String)
          level = level.downcase.to_sym
          LEVELS.index(level)
        elsif level.is_a?(Integer) && defined?(::Logger::Severity)
          # Mapping of Rails and Ruby Logger levels to Sapience levels
          @@map_levels ||= begin
            levels = []
            ::Logger::Severity.constants.each do |constant|
              levels[::Logger::Severity.const_get(constant)] = LEVELS.find_index(constant.downcase.to_sym) || LEVELS.find_index(:error)
            end
            levels
          end
          @@map_levels[level]
        end
      fail "Invalid level:#{level.inspect} being requested. Must be one of #{LEVELS.inspect}" unless index
      index
    end

    def default_level_index
      Thread.current[:sapience_silence] || @default_level_index
    end


    # Sets the level at which backtraces should be captured
    # for every log message.
    #
    # By enabling backtrace capture the filename and line number of where
    # message was logged can be written to the log file. Additionally, the backtrace
    # can be forwarded to error management services such as Bugsnag.
    #
    # Warning:
    #   Capturing backtraces is very expensive and should not be done all
    #   the time. It is recommended to run it at :error level in production.
    def backtrace_level=(level)
      @backtrace_level       = level
      # For performance reasons pre-calculate the level index
      @backtrace_level_index = level.nil? ? 65_535 : level_to_index(level)
    end

    # Returns [String] name of this host for logging purposes
    # Note: Not all appenders use `host`
    def host
      @host ||= Socket.gethostname
    end


  end
end
