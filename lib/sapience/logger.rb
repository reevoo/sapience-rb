require "concurrent"

# rubocop:disable ClassVars
module Sapience
  # Logger stores the class name to be used for all log messages so that every
  # log message written by this instance will include the class name
  class Logger < Base # rubocop:disable ClassLength, ClassVars
    include Sapience::Concerns::Compatibility

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

    # Returns [Integer] the number of log entries that have not been written
    # to the appenders
    #
    # When this number grows it is because the logging appender thread is not
    # able to write to the appenders fast enough. Either reduce the amount of
    # logging, increase the log level, reduce the number of appenders, or
    # look into speeding up the appenders themselves
    def self.queue_size
      queue.size
    end

    # Flush all queued log entries disk, database, etc.
    #  All queued log messages are written and then each appender is flushed in turn
    def self.flush
      msg = "Flushing appenders with #{queue_size} log messages on the queue"
      if queue_size > 1_000
        logger.warn msg
      elsif queue_size > 100
        logger.info msg
      elsif queue_size > 0
        logger.trace msg
      end
      process_request(:flush)
    end

    # Close all appenders and flush any outstanding messages
    def self.close
      msg = "Closing appenders with #{queue_size} log messages on the queue"
      if queue_size > 1_000
        logger.warn msg
      elsif queue_size > 100
        logger.info msg
      elsif queue_size > 0
        logger.trace msg
      end
      process_request(:close)
    end

    @@lag_check_interval = 5000
    @@lag_threshold_s    = 30

    # Returns the check_interval which is the number of messages between checks
    # to determine if the appender thread is falling behind
    def self.lag_check_interval
      @@lag_check_interval
    end

    # Set the check_interval which is the number of messages between checks
    # to determine if the appender thread is falling behind
    def self.lag_check_interval=(lag_check_interval)
      @@lag_check_interval = lag_check_interval
    end

    # Returns the amount of time in seconds
    # to determine if the appender thread is falling behind
    def self.lag_threshold_s
      @@lag_threshold_s
    end

    # Allow the internal logger to be overridden from its default to STDERR
    #   Can be replaced with another Ruby logger or Rails logger, but never to
    #   Sapience::Logger itself since it is for reporting problems
    #   while trying to log to the various appenders
    def self.logger=(logger)
      @@logger = logger
    end

    # Place log request on the queue for the Appender thread to write to each
    # appender in the order that they were registered
    def log(log, message = nil, progname = nil, &block)
      # Compatibility with ::Logger
      return add(log, message, progname, &block) unless log.is_a?(Sapience::Log)
      self.class.queue << log if @@appender_thread
    end

    @@appender_thread    = nil
    @@queue              = Queue.new

    # Queue to hold messages that need to be logged to the various appenders
    def self.queue
      @@queue
    end

    # Internal logger for Sapience
    #   For example when an appender is not working etc..
    #   By default logs to STDERR
    def self.logger
      @@logger ||= begin
        l      = Sapience::Appender::File.new(STDERR, :warn)
        l.name = name
        l
      end
    end

    # Start the appender thread
    def self.start_appender_thread
      return false if appender_thread_active?
      @@appender_thread = Thread.new { appender_thread }
      fail "Failed to start Appender Thread" unless @@appender_thread
      true
    end

    # Returns true if the appender_thread is active
    def self.appender_thread_active?
      @@appender_thread && @@appender_thread.alive?
    end

    # Separate appender thread responsible for reading log messages and
    # calling the appenders in it's thread
    # rubocop:disable BlockNesting, AssignmentInCondition, PerceivedComplexity, CyclomaticComplexity, AbcSize, LineLength, RescueException
    def self.appender_thread
      # This thread is designed to never go down unless the main thread terminates
      # Before terminating at_exit is used to flush all the appenders
      #
      # Should any appender fail to log or flush, the exception is logged and
      # other appenders will still be called
      Thread.current.name = "Sapience::AppenderThread"
      logger.trace "V#{VERSION} Appender thread active"
      begin
        count = 0
        while message = queue.pop
          if message.is_a?(Log)
            Sapience.appenders.each do |appender|
              begin
                appender.log(message)
              rescue Exception => exc
                logger.error "Appender thread: Failed to log to appender: #{appender.inspect}", exc
              end
            end
            count += 1
            # Check every few log messages whether this appender thread is falling behind
            if count > lag_check_interval
              if (diff = Time.now - message.time) > lag_threshold_s
                logger.warn "Appender thread has fallen behind by #{diff} seconds with #{queue_size} messages queued up. Consider reducing the log level or changing the appenders"
              end
              count = 0
            end
          else
            case message[:command]
            when :flush
              Sapience.appenders.each do |appender|
                begin
                  logger.trace "Appender thread: Flushing appender: #{appender.name}"
                  appender.flush
                rescue Exception => exc
                  logger.error "Appender thread: Failed to flush appender: #{appender.inspect}", exc
                end
              end

              message[:reply_queue] << true if message[:reply_queue]
              logger.trace "Appender thread: All appenders flushed"
            when :close
              Sapience.appenders.each do |appender|
                begin
                  logger.trace "Appender thread: Closing appender: #{appender.name}"
                  appender.flush
                  appender.close
                  Sapience.remove_appender(appender)
                rescue Exception => exc
                  logger.error "Appender thread: Failed to close appender: #{appender.inspect}", exc
                end
              end

              message[:reply_queue] << true if message[:reply_queue]
              logger.trace "Appender thread: All appenders flushed"
            else
              logger.warn "Appender thread: Ignoring unknown command: #{message[:command]}"
            end
          end
        end
      rescue Exception => exception
        # This block may be called after the file handles have been released by Ruby
        begin
          logger.error "Appender thread restarting due to exception", exception
        rescue Exception
          nil
        end
        retry
      ensure
        @@appender_thread = nil
        # This block may be called after the file handles have been released by Ruby
        begin
          logger.trace "Appender thread has stopped"
        rescue Exception
          nil
        end
      end
    end
    # rubocop:enable BlockNesting, AssignmentInCondition, PerceivedComplexity, CyclomaticComplexity, AbcSize, LineLength, RescueException

    # Close all appenders and flush any outstanding messages
    def self.process_request(command)
      return false unless appender_thread_active?

      reply_queue = Queue.new
      queue << { command: command, reply_queue: reply_queue }
      reply_queue.pop
    end
  end
end
