# frozen_string_literal: true
require "concurrent"

# rubocop:disable ClassVars, Style/SafeNavigation
module Sapience
  # Logger stores the class name to be used for all log messages so that every
  # log message written by this instance will include the class name
  class Logger < Base
    include Sapience::Concerns::Compatibility

    # Flush all queued log entries disk, database, etc.
    #  All queued log messages are written and then each appender is flushed in turn
    def self.flush # rubocop:disable AbcSize
      return unless appender_thread
      appender_thread << lambda do
        Sapience.appenders.each do |appender|
          next unless appender.valid?
          begin
            logger.trace "Appender thread: Flushing appender: #{appender.class.name}"
            appender.flush
          rescue StandardError => exc
            $stderr.write("Appender thread: Failed to flush to appender: #{appender.inspect}\n #{exc.inspect}")
          end
        end

        logger.trace "Appender thread: All appenders flushed"
      end
    end

    # Close all appenders and flush any outstanding messages
    def self.close
      return unless appender_thread
      appender_thread << lambda do
        Sapience.appenders.each do |appender|
          next unless appender.valid?
          begin
            close_appender(appender)
          rescue StandardError => exc
            logger.error "Appender thread: Failed to close appender: #{appender.inspect}", exc
          end
        end
        logger.trace "Appender thread: All appenders flushed"
      end
    end

    def self.close_appender(appender)
      logger.trace "Appender thread: Closing appender: #{appender.name}"
      appender.flush
      appender.close
      Sapience.remove_appender(appender)
    end

    @@appender_thread = nil
    @@logger = nil

    # Internal logger for Sapience
    #   For example when an appender is not working etc..
    #   By default logs to STDERR
    def self.logger
      @@logger ||= Sapience[Sapience]
    end

    # Start the appender thread
    def self.start_appender_thread
      return false if appender_thread_active?

      @@appender_thread = Sapience.log_executor_class.new
      fail "Failed to start Appender Thread" unless @@appender_thread
      true
    end

    def self.start_invalid_appenders_task
      @@invalid_appenders_task = Concurrent::TimerTask.new(execution_interval: 120, timeout_interval: 5) do
        Sapience.appenders.each do |appender|
          next if appender.valid?
          logger.warn { "#{appender.class} is not valid. #{appender::VALIDATION_MESSAGE}" }
        end
      end
      invalid_appenders_task.execute
    end

    # Returns true if the appender_thread is active
    def self.appender_thread_active?
      @@appender_thread && @@appender_thread.running?
    end

    # Separate appender thread responsible for reading log messages and
    # calling the appenders in it's thread
    def self.appender_thread
      @@appender_thread
    end

    def self.invalid_appenders_task
      @@invalid_appenders_task
    end

    # Allow the internal logger to be overridden from its default to STDERR
    #   Can be replaced with another Ruby logger or Rails logger, but never to
    #   Sapience::Logger itself since it is for reporting problems
    #   while trying to log to the various appenders
    def self.logger=(logger)
      @@logger = logger
    end

    # Returns a Logger instance
    #
    # Return the logger for a specific class, supports class specific log levels
    #   logger = Sapience::Logger.new(self)
    # OR
    #   logger = Sapience::Logger.new('MyClass')
    #
    # Parameters:
    #  application
    #    A class, module or a string with the application/class name
    #    to be used in the logger
    #
    #  level
    #    The initial log level to start with for this logger instance
    #    Default: Sapience.config.default_level
    #
    #  filter [Regexp|Proc]
    #    RegExp: Only include log messages where the class name matches the supplied
    #    regular expression. All other messages will be ignored
    #    Proc: Only include log messages where the supplied Proc returns true
    #          The Proc must return true or false
    def initialize(klass, level = nil, filter = nil)
      super
    end

    # Place log request on the queue for the Appender thread to write to each
    # appender in the order that they were registered
    def log(log, message = nil, progname = nil, &block)
      # Compatibility with ::Logger
      return add(log, message, progname, &block) unless log.is_a?(Sapience::Log)
      if @@appender_thread
        @@appender_thread << lambda do
          Sapience.appenders.each do |appender|
            next unless appender.valid?
            begin
              appender.log(log)
            rescue StandardError => exc
              $stderr.write("Appender thread: Failed to log to appender: #{appender.inspect}\n #{exc.inspect}")
            end
          end
          Sapience.clear_tags!
        end
      end
    end

    def flush
      self.class.flush
    end
  end
end
# rubocop:enable ClassVars, Style/SafeNavigation
