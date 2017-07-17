# frozen_string_literal: true
module Sapience
  # rubocop:disable ClassLength
  class Base
    # Class name to be logged
    attr_accessor :name, :filter
    include Sapience::LogMethods

    # Set the logging level for this logger
    #
    # Note: This level is only for this particular instance. It does not override
    #   the log level in any logging instance or the default log level
    #   Sapience.config.default_level
    #
    # Must be one of the values in Sapience::LEVELS, or
    # nil if this logger instance should use the global default level
    def level=(level)
      @level_index = Sapience.config.level_to_index(level)
      @level       = Sapience.config.index_to_level(@level_index)
    end

    # Returns the current log level if set, otherwise it returns the global
    # default log level
    def level
      @level || Sapience.config.default_level
    end

    # TODO: Move this to logger.rb?
    # Implement the log level calls
    #   logger.debug(message, hash|exception=nil, &block)
    #
    # Implement the log level query
    #   logger.debug?
    #
    # Parameters:
    #   message
    #     [String] text message to be logged
    #     Should always be supplied unless the result of the supplied block returns
    #     a string in which case it will become the logged message
    #     Default: nil
    #
    #   payload
    #     [Hash|Exception] Optional hash payload or an exception to be logged
    #     Default: nil
    #
    #   exception
    #     [Exception] Optional exception to be logged
    #     Allows both an exception and a payload to be logged
    #     Default: nil
    #
    # Examples:
    #    require 'sapience'
    #
    #    # Enable trace level logging
    #    Sapience.config.default_level = :info
    #
    #    # Log to screen
    #    Sapience.add_appender(:stream, io: STDOUT, formatter: :color)
    #
    #    # And log to a file at the same time
    #    Sapience.add_appender(:stream, file_name: 'application.log', formatter: :color)
    #
    #    logger = Sapience['MyApplication']
    #    logger.debug("Only display this if log level is set to Debug or lower")
    #
    #    # Log information along with a text message
    #    logger.info("Request received", user: "joe", duration: 100)
    #
    #    # Log an exception
    #    logger.info("Parsing received XML", exc)
    #

    # :nodoc:
    def tagged(*tags, &block)
      Sapience.tagged(*tags, &block)
    end

    # :nodoc:
    alias with_tags tagged

    # :nodoc:
    def tags
      Sapience.tags
    end

    # :nodoc:
    def push_tags(*tags)
      Sapience.push_tags(*tags)
    end
    alias tags= push_tags

    # :nodoc:
    def pop_tags(quantity = 1)
      Sapience.pop_tags(quantity)
    end

    # :nodoc:
    def silence(new_level = :error, &block)
      Sapience.silence(new_level, &block)
    end

    # :nodoc:
    def fast_tag(tag, &block)
      Sapience.fast_tag(tag, &block)
    end

    # Returns [Sapience::Formatters::Default] formatter default for this subscriber
    def default_formatter
      Sapience::Formatters::Default.new
    end

    def app_name
      Sapience.app_name
    end

    # Allow host name to be set globally or per subscriber
    def host
      Sapience.config.host
    end

    # Thread specific context information to be logged with every log entry
    #
    # Add a payload to all log calls on This Thread within the supplied block
    #
    #   logger.with_payload(tracking_number: 12345) do
    #     logger.debug('Hello World')
    #   end
    #
    # If a log call already includes a pyload, this payload will be merged with
    # the supplied payload, with the supplied payload taking precedence
    #
    #   logger.with_payload(tracking_number: 12345) do
    #     logger.debug('Hello World', result: 'blah')
    #   end
    def with_payload(payload)
      current_payload                   = self.payload
      Thread.current[:sapience_payload] = current_payload ? current_payload.merge(payload) : payload
      yield
    ensure
      Thread.current[:sapience_payload] = current_payload
    end

    # Returns [Hash] payload to be added to every log entry in the current scope
    # on this thread.
    # Returns nil if no payload is currently set
    def payload
      Thread.current[:sapience_payload]
    end

    protected

    # Write log data to underlying data storage
    def log(_log_)
      fail NotImplementedError, "Logging Appender must implement #log(log)"
    end

    private

    # Initializer for Abstract Class Sapience::Base
    #
    # Parameters
    #  klass [String]
    #   Name of the class, module, or other identifier for which the log messages
    #   are being logged
    #
    #  level [Symbol]
    #    Only allow log entries of this level or higher to be written to this appender
    #    For example if set to :warn, this appender would only log :warn and :fatal
    #    log messages when other appenders could be logging :info and lower
    #
    #  filter [Regexp|Proc]
    #    RegExp: Only include log messages where the class name matches the supplied
    #    regular expression. All other messages will be ignored
    #    Proc: Only include log messages where the supplied Proc returns true
    #          The Proc must return true or false
    # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength
    def initialize(klass, level = nil, filter = nil)
      # Support filtering all messages to this logger using a Regular Expression
      # or Proc
      fail ArgumentError, ":filter must be a Regexp or Proc" unless filter.nil? || filter.is_a?(Regexp) || filter.is_a?(Proc)

      @filter = filter.is_a?(Regexp) ? filter.freeze : filter
      @name   = klass if klass.is_a?(String)
      @name ||= klass.name if klass.respond_to?(:name)
      @name ||= klass.class.name

      if level.nil?
        # Allow the global default level to determine this loggers log level
        @level_index = nil
        @level       = nil
      else
        self.level = level
      end
    end
    # rubocop:enable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength

    # Return the level index for fast comparisons
    # Returns the global default level index if the level has not been explicitly
    # set for this instance
    def level_index
      @level_index || Sapience.config.default_level_index
    end

    # Whether to log the supplied message based on the current filter if any
    def include_message?(log)
      return true if @filter.nil?

      if @filter.is_a?(Regexp)
        !(@filter =~ log.name).nil?
      elsif @filter.is_a?(Proc)
        @filter.call(log) == true
      end
    end

    # Whether the log message should be logged for the current logger or appender
    def should_log?(log)
      # Ensure minimum log level is met, and check filter
      (level_index <= (log.level_index || 0)) && include_message?(log)
    end

    # TODO: Move this to logger.rb?
    # Log message at the specified level
    # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength
    def log_internal(level, index, message = nil, payload = nil, exception = nil)
      # Exception being logged?
      if exception.nil? && payload.nil? && message.respond_to?(:backtrace) && message.respond_to?(:message)
        exception = message
        message   = nil
      elsif exception.nil? && payload && payload.respond_to?(:backtrace) && payload.respond_to?(:message)
        exception = payload
        payload   = nil
      end

      # Add result of block as message or payload if not nil
      if block_given? && (result = yield)
        if result.is_a?(String)
          message = message.nil? ? result : "#{message} -- #{result}"
        elsif message.nil? && result.is_a?(Hash)
          message = result
        elsif payload && payload.respond_to?(:merge)
          payload.merge(result)
        else
          payload = result
        end
      end

      # Add scoped payload
      if self.payload
        payload = payload.nil? ? self.payload : self.payload.merge(payload)
      end

      merged_tags = merge_tags_with_payload(payload)
      # Add caller stack trace
      backtrace = extract_backtrace if index >= Sapience.config.backtrace_level_index

      log = Log.new(level, Thread.current.name, name, message, payload, Time.now, nil, merged_tags, index, exception, nil, backtrace)

      # Logging Hash only?
      # logger.info(name: 'value')

      if payload.nil? && exception.nil? && message.is_a?(Hash)
        payload           = message.dup
        min_duration      = payload.delete(:min_duration) || 0.0
        log.exception     = payload.delete(:exception)
        log.message       = payload.delete(:message)
        log.metric        = payload.delete(:metric)
        log.metric_amount = payload.delete(:metric_amount) || 1
        if (duration = payload.delete(:duration))
          return false if duration <= min_duration
          log.duration = duration
        end
        log.payload = payload unless payload.empty?
      end
      self.log(log) if include_message?(log)
    end
    # rubocop:enable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength

    SELF_PATTERN = File.join("lib", "sapience")

    def merge_tags_with_payload(payload = {})
      merged_tags = tags.dup
      if payload.is_a?(Hash)
        payload_tags = payload.delete(:tags) || []
        merged_tags.concat(payload_tags) unless payload_tags.empty?
      end
      merged_tags.uniq
    end

    # Extract the callers backtrace leaving out Sapience
    def extract_backtrace
      stack = caller
      while (first = stack.first) && first.include?(SELF_PATTERN)
        stack.shift
      end
      stack
    end

    # Measure the supplied block and log the message
    # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength
    def measure_internal(level, index, message, params)
      params.dup
      start     = Time.now
      exception = nil
      begin
        if block_given?
          result    =
            if (silence_level = params[:silence])
              # In case someone accidentally sets `silence: true` instead of `silence: :error`
              silence_level = :error if silence_level == true
              silence(silence_level) { yield(params) }
            else
              yield(params)
            end
          exception = params[:exception]
          result
        end
      rescue Exception => exc # rubocop:disable RescueException
        exception = exc
      ensure
        end_time           = Time.now
        # Extract options after block completes so that block can modify any of the options
        log_exception      = params[:log_exception] || :partial
        on_exception_level = params[:on_exception_level]
        min_duration       = params[:min_duration] || 0.0
        payload            = params[:payload]
        metric             = params[:metric]
        duration           =
          if block_given?
            1000.0 * (end_time - start)
          else
            params[:duration] || fail("Mandatory block missing when :duration option is not supplied")
          end

        # Add scoped payload
        if self.payload
          payload = payload.nil? ? self.payload : self.payload.merge(payload)
        end

        merged_tags = merge_tags_with_payload(payload)

        if exception
          logged_exception = exception
          backtrace        = nil
          case log_exception
          when :full
            # On exception change the log level
            if on_exception_level
              level = on_exception_level
              index = Sapience.config.level_to_index(level)
            end
          when :partial
            # On exception change the log level
            if on_exception_level
              level = on_exception_level
              index = Sapience.config.level_to_index(level)
            end
            message          = "#{message} -- Exception: #{exception.class}: #{exception.message}"
            logged_exception = nil
            backtrace        = exception.backtrace
          else
            # Log the message with its duration but leave out the exception that was raised
            logged_exception = nil
            backtrace        = exception.backtrace
          end

          log = Log.new(level, Thread.current.name, name, message, payload, end_time, duration, merged_tags, index, logged_exception, metric, backtrace) # rubocop:disable LineLength
          self.log(log) if include_message?(log)
          fail exception
        elsif duration >= min_duration
          # Only log if the block took longer than 'min_duration' to complete
          # Add caller stack trace
          backtrace = extract_backtrace if index >= Sapience.config.backtrace_level_index

          log = Log.new(level, Thread.current.name, name, message, payload, end_time, duration, merged_tags, index, nil, metric, backtrace) # rubocop:disable LineLength
          self.log(log) if include_message?(log)
        end
      end
    end
    # rubocop:enable AbcSize, PerceivedComplexity, CyclomaticComplexity, LineLength
  end
  # rubocop:enable ClassLength
end
