require "concurrent"
require "socket"

module Sapience
  DEFAULT_CONFIGURATION = {
    application:   "Sapience Application",
    default_level: :trace,
    appender:      [
      { io: STDOUT, formatter: :color },
      { appender: :sentry },
      { appender: :statsd, url: "udp://0.0.0.0:2222" },
    ],
  }.freeze

  # Logging levels in order of most detailed to most severe
  LEVELS                = [:trace, :debug, :info, :warn, :error, :fatal]

  # Return a logger for the supplied class or class_name
  def self.[](klass)
    Sapience::Logger.new(klass)
  end

  # Sets the global default log level
  def self.default_level=(level)
    @@default_level       = level
    # For performance reasons pre-calculate the level index
    @@default_level_index = level_to_index(level)
  end

  # Returns the global default log level
  def self.default_level
    @@default_level
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
  def self.backtrace_level=(level)
    @@backtrace_level       = level
    # For performance reasons pre-calculate the level index
    @@backtrace_level_index = level.nil? ? 65_535 : level_to_index(level)
  end

  # Returns the current backtrace level
  def self.backtrace_level
    @@backtrace_level
  end

  # Returns the current backtrace level index
  # For internal use only
  def self.backtrace_level_index #:nodoc
    @@backtrace_level_index
  end

  # Returns [String] name of this host for logging purposes
  # Note: Not all appenders use `host`
  def self.host
    @@host ||= Socket.gethostname
  end

  # Override the default host name
  def self.host=(host)
    @@host = host
  end

  # Returns [String] name of this application for logging purposes
  # Note: Not all appenders use `application`
  def self.application
    @@application
  end

  # Override the default application
  def self.application=(application)
    @@application = application
  end

  @@application = "Sapience"

  # Add a new logging appender as a new destination for all log messages
  # emitted from Sapience
  #
  # Appenders will be written to in the order that they are added
  #
  # If a block is supplied then it will be used to customize the format
  # of the messages sent to that appender. See Sapience::Logger.new for
  # more information on custom formatters
  #
  # Parameters
  #   file_name: [String]
  #     File name to write log messages to.
  #
  #   Or,
  #   io: [IO]
  #     An IO Stream to log to.
  #     For example STDOUT, STDERR, etc.
  #
  #   Or,
  #   appender: [Symbol|Sapience::Subscriber]
  #     A symbol identifying the appender to create.
  #     For example:
  #       :bugsnag, :elasticsearch, :graylog, :http, :mongodb, :new_relic, :splunk_http, :syslog, :wrapper
  #          Or,
  #     An instance of an appender derived from Sapience::Subscriber
  #     For example:
  #       Sapience::Appender::Http.new(url: 'http://localhost:8088/path')
  #
  #   Or,
  #   logger: [Logger|Log4r]
  #     An instance of a Logger or a Log4r logger.
  #
  #   level: [:trace | :debug | :info | :warn | :error | :fatal]
  #     Override the log level for this appender.
  #     Default: Sapience.default_level
  #
  #   formatter: [Symbol|Object|Proc]
  #     Any of the following symbol values: :default, :color, :json
  #       Or,
  #     An instance of a class that implements #call
  #       Or,
  #     A Proc to be used to format the output from this appender
  #     Default: :default
  #
  #   filter: [Regexp|Proc]
  #     RegExp: Only include log messages where the class name matches the supplied.
  #     regular expression. All other messages will be ignored.
  #     Proc: Only include log messages where the supplied Proc returns true
  #           The Proc must return true or false.
  #
  # Examples:
  #
  #   # Send all logging output to Standard Out (Screen)
  #   Sapience.add_appender(io: STDOUT)
  #
  #   # Send all logging output to a file
  #   Sapience.add_appender(file_name: 'logfile.log')
  #
  #   # Send all logging output to a file and only :info and above to standard output
  #   Sapience.add_appender(file_name: 'logfile.log')
  #   Sapience.add_appender(io: STDOUT, level: :info)
  #
  # Log to log4r, Logger, etc.:
  #
  #   # Send logging output to an existing logger
  #   require 'logger'
  #   require 'sapience'
  #
  #   # Built-in Ruby logger
  #   log = Logger.new(STDOUT)
  #   log.level = Logger::DEBUG
  #
  #   Sapience.default_level = :debug
  #   Sapience.add_appender(logger: log)
  #
  #   logger = Sapience['Example']
  #   logger.info "Hello World"
  #   logger.debug("Login time", user: 'Joe', duration: 100, ip_address: '127.0.0.1')
  def self.add_appender(options, deprecated_level = nil, &block)
    fail ArgumentError, "options should be a hash" unless options.is_a?(Hash)
    options  = options.dup
    appender = appender_from_options(options, &block)
    @@appenders << appender

    # Start appender thread if it is not already running
    Sapience::Logger.start_appender_thread
    appender
  end

  # Remove an existing appender
  # Currently only supports appender instances
  def self.remove_appender(appender)
    @@appenders.delete(appender)
  end

  # Returns [Sapience::Subscriber] a copy of the list of active
  # appenders for debugging etc.
  # Use Sapience.add_appender and Sapience.remove_appender
  # to manipulate the active appenders list
  def self.appenders
    @@appenders.clone
  end

  # Wait until all queued log messages have been written and flush all active
  # appenders
  def self.flush
    Sapience::Logger.flush
  end

  # Close and flush all appenders
  def self.close
    Sapience::Logger.close
  end

  # After forking an active process call Sapience.reopen to re-open
  # any open file handles etc to resources
  #
  # Note: Only appenders that implement the reopen method will be called
  def self.reopen
    @@appenders.each { |appender| appender.reopen if appender.respond_to?(:reopen) }
    # After a fork the appender thread is not running, start it if it is not running
    Sapience::Logger.start_appender_thread
  end

  # Add signal handlers for Sapience
  #
  # Two signal handlers will be registered by default:
  #
  # 1. Changing the log_level:
  #
  #   The log level can be changed without restarting the process by sending the
  #   log_level_signal, which by default is 'USR2'
  #
  #   When the log_level_signal is raised on this process, the global default log level
  #   rotates through the following log levels in the following order, starting
  #   from the current global default level:
  #     :warn, :info, :debug, :trace
  #
  #   If the current level is :trace it wraps around back to :warn
  #
  # 2. Logging a Ruby thread dump
  #
  #   When the signal is raised on this process, Sapience will write the list
  #   of threads to the log file, along with their back-traces when available
  #
  #   It is recommended to name any threads you create in the application, by
  #   calling the following from within the thread itself:
  #      Thread.current.name = 'My Worker'
  #
  #
  # Note:
  #   To only register one of the signal handlers, set the other to nil
  def self.add_signal_handler(log_level_signal = "USR2", thread_dump_signal = "TTIN", _gc_log_microseconds = 100_000)
    Signal.trap(log_level_signal) do
      index     = (default_level == :trace) ? LEVELS.find_index(:error) : LEVELS.find_index(default_level)
      new_level = LEVELS[index - 1]
      self["Sapience"].warn "Changed global default log level to #{new_level.inspect}"
      self.default_level = new_level
    end if log_level_signal

    Signal.trap(thread_dump_signal) do
      logger = Sapience["Thread Dump"]
      Thread.list.each do |thread|
        next if thread == Thread.current
        message = thread.name
        if backtrace = thread.backtrace
          message += "\n"
          message << backtrace.join("\n")
        end
        tags = thread[:sapience_tags]
        tags = tags.nil? ? [] : tags.clone
        logger.tagged(tags) { logger.warn(message) }
      end
    end if thread_dump_signal

    true
  end

  # If the tag being supplied is definitely a string then this fast
  # tag api can be used for short lived tags
  def self.fast_tag(tag)
    (Thread.current[:sapience_tags] ||= []) << tag
    yield
  ensure
    Thread.current[:sapience_tags].pop
  end

  # Add the supplied named tags to the list of tags to log for this thread whilst
  # the supplied block is active.
  #
  # Returns result of block
  #
  # Example:
  def self.named_tags(tag)
    (Thread.current[:sapience_tags] ||= []) << tag
    yield
  ensure
    Thread.current[:sapience_tags].pop
  end

  # Add the supplied tags to the list of tags to log for this thread whilst
  # the supplied block is active.
  # Returns result of block
  def self.tagged(*tags)
    new_tags = push_tags(*tags)
    yield self
  ensure
    pop_tags(new_tags.size)
  end

  # Returns a copy of the [Array] of [String] tags currently active for this thread
  # Returns nil if no tags are set
  def self.tags
    # Since tags are stored on a per thread basis this list is thread-safe
    t = Thread.current[:sapience_tags]
    t.nil? ? [] : t.clone
  end

  # Add tags to the current scope
  # Returns the list of tags pushed after flattening them out and removing blanks
  def self.push_tags(*tags)
    # Need to flatten and reject empties to support calls from Rails 4
    new_tags                              = tags.flatten.collect(&:to_s).reject(&:empty?)
    t                                     = Thread.current[:sapience_tags]
    Thread.current[:sapience_tags] = t.nil? ? new_tags : t.concat(new_tags)
    new_tags
  end

  # Remove specified number of tags from the current tag list
  def self.pop_tags(quantity = 1)
    t = Thread.current[:sapience_tags]
    t.pop(quantity) unless t.nil?
  end

  # Silence noisy log levels by changing the default_level within the block
  #
  # This setting is thread-safe and only applies to the current thread
  #
  # Any threads spawned within the block will not be affected by this setting
  #
  # #silence can be used to both raise and lower the log level within
  # the supplied block.
  #
  # Example:
  #
  #   # Perform trace level logging within the block when the default is higher
  #   Sapience.default_level = :info
  #
  #   logger.debug 'this will _not_ be logged'
  #
  #   Sapience.silence(:trace) do
  #     logger.debug "this will be logged"
  #   end
  #
  # Parameters
  #   new_level
  #     The new log level to apply within the block
  #     Default: :error
  #
  # Example:
  #   # Silence all logging for this thread below :error level
  #   Sapience.silence do
  #     logger.info "this will _not_ be logged"
  #     logger.warn "this neither"
  #     logger.error "but errors will be logged"
  #   end
  #
  # Note:
  #   #silence does not affect any loggers which have had their log level set
  #   explicitly. I.e. That do not rely on the global default level
  def self.silence(new_level = :error)
    current_index                            = Thread.current[:sapience_silence]
    Thread.current[:sapience_silence] = Sapience.level_to_index(new_level)
    yield
  ensure
    Thread.current[:sapience_silence] = current_index
  end

  private

  @@appenders = Concurrent::Array.new

  def self.default_level_index
    Thread.current[:sapience_silence] || @@default_level_index
  end

  # Returns the symbolic level for the supplied level index
  def self.index_to_level(level_index)
    LEVELS[level_index]
  end

  # Internal method to return the log level as an internal index
  # Also supports mapping the ::Logger levels to Sapience levels
  def self.level_to_index(level)
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

  # Returns [Sapience::Subscriber] appender for the supplied options
  def self.appender_from_options(options, &block)
    if options[:io] || options[:file_name]
      Sapience::Appender::File.new(options, &block)
    elsif appender = options.delete(:appender)
      if appender.is_a?(Symbol)
        constantize_symbol(appender).new(options)
      elsif appender.is_a?(Subscriber)
        appender
      else
        fail(ArgumentError, "Parameter :appender must be either a Symbol or an object derived from Sapience::Subscriber, not: #{appender.inspect}")
      end
    elsif options[:logger]
      Sapience::Appender::Wrapper.new(options, &block)
    end
  end

  def self.constantize_symbol(symbol, namespace = "Sapience::Appender")
    klass = "#{namespace}::#{camelize(symbol.to_s)}"
    begin
      if RUBY_VERSION.to_i >= 2
        Object.const_get(klass)
      else
        klass.split("::").inject(Object) { |o, name| o.const_get(name) }
      end
    rescue NameError
      raise(ArgumentError, "Could not convert symbol: #{symbol} to a class in: #{namespace}. Looking for: #{klass}")
    end
  end

  # Borrow from Rails, when not running Rails
  def self.camelize(term)
    string = term.to_s
    string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{Regexp.last_match[1]}#{inflections.acronyms[Regexp.last_match[2]] || Regexp.last_match[2].capitalize}" }
    string.gsub!("/".freeze, "::".freeze)
    string
  end

  # Initial default Level for all new instances of Sapience::Logger
  @@default_level         = :info
  @@default_level_index   = level_to_index(@@default_level)
  @@backtrace_level       = :error
  @@backtrace_level_index = level_to_index(@@backtrace_level)
end
