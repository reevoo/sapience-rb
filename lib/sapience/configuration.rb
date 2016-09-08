require "ostruct"

module Sapience
  # rubocop:disable ClassVars
  class Configuration
    attr_reader :default_level, :backtrace_level, :backtrace_level_index
    attr_writer :host
    attr_accessor :application, :ap_options, :appenders, :log_executor

    SUPPORTED_EXECUTORS = %i(single_thread_executor immediate_executor).freeze
    DEFAULT = {
      log_level:   :info,
      application: "Sapience",
      host:        nil,
      ap_options:  { multiline: false },
      appenders:   [{ stream: { io: STDOUT, formatter: :color } }],
      log_executor: :single_thread_executor,
    }.freeze

    # Initial default Level for all new instances of Sapience::Logger
    def initialize(options = {}) # rubocop:disable AbcSize
      fail ArgumentError, "options need to be a hash" unless options.is_a?(Hash)
      @options             = DEFAULT.merge(options.deep_symbolize_keys!)
      validate_log_executor!(@options[:log_executor])
      self.default_level   = @options[:log_level].to_sym
      self.backtrace_level = @options[:log_level].to_sym
      self.application     = @options[:application]
      self.host            = @options[:host]
      self.ap_options      = @options[:ap_options]
      self.appenders       = @options[:appenders]
      self.log_executor    = @options[:log_executor].to_sym
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
    def level_to_index(level) # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity
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
            levels[::Logger::Severity.const_get(constant)] = LEVELS.find_index(constant.downcase.to_sym) || LEVELS.find_index(:error) # rubocop:disable LineLength
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

    def validate_log_executor!(log_executor)
      return true if SUPPORTED_EXECUTORS.include?(log_executor)
      fail ArgumentError, "#{log_executor} is unsupported. Use (#{SUPPORTED_EXECUTORS.join(", ")})"
    end
  end
end
