require "concurrent"
require "socket"
require "sapience/descendants"
require "English"

# Example:
#
# Sapience.configure do |config|
#   config.default_level   = ENV.fetch('SAPIENCE_DEFAULT_LEVEL') { :info }.to_sym
#   config.backtrace_level = ENV.fetch('SAPIENCE_BACKTRACE_LEVEL') { :info }.to_sym
#   config.app_name        = 'TestApplication'
#   config.host            = ENV.fetch('SAPIENCE_HOST', nil)
#   config.ap_options      = { multiline: false }
#   config.appenders       = [
#     { stream: { io: STDOUT, formatter: :color } },
#     { statsd: { url: 'udp://localhost:2222' } },
#     { sentry: { dsn: 'https://foobar:443' } },
#   ]
# end

# rubocop:disable ClassVars
module Sapience
  UnknownClass   = Class.new(NameError)
  AppNameMissing = Class.new(NameError)
  TestException  = Class.new(StandardError)
  @@configured = false

  # Logging levels in order of most detailed to most severe
  LEVELS = [:trace, :debug, :info, :warn, :error, :fatal].freeze
  APP_NAME     = "APP_NAME".freeze
  DEFAULT_ENV  = "default".freeze
  RACK_ENV     = "RACK_ENV".freeze
  RAILS_ENV    = "RAILS_ENV".freeze
  SAPIENCE_ENV = "SAPIENCE_ENV".freeze

  def self.configure(force: false)
    yield config if block_given?
    return config if configured? && force == false
    reset_appenders!
    add_appenders(*config.appenders)
    @@configured = true

    config
  end

  def self.config_hash
    @@config_hash ||= ConfigLoader.load_from_file
  end

  def self.config
    @@config ||= begin
      options   = config_hash[environment]
      options ||= default_options(config_hash)
      Configuration.new(options)
    end
  end

  def self.configured?
    @@configured
  end

  def self.default_options(options = {})
    unless environment =~ /default|rspec/
      warn "No configuration for environment #{environment}. Using 'default'"
    end
    options[DEFAULT_ENV]
  end

  def self.reset!
    @@config = nil
    @@logger = nil
    @@metrics = nil
    @@environment = nil
    @@app_name = nil
    @@configured = false
    @@config_hash = nil
    clear_tags!
    reset_appenders!
  end

  def self.reset_appenders!
    @@appenders = Concurrent::Array.new
  end

  # TODO: Default to SAPIENCE_ENV (if present it should be returned first)
  def self.environment
    @@environment ||=
      ENV.fetch(SAPIENCE_ENV) do
        ENV.fetch(RAILS_ENV) do
          ENV.fetch(RACK_ENV) do
            if defined?(::Rails) && ::Rails.respond_to?(:env)
              ::Rails.env
            else
              warn "Sapience is going to use default configuration"
              DEFAULT_ENV
            end
          end
        end
      end
  end

  def self.app_name
    @@app_name ||= config.app_name
    @@app_name ||= config_hash.fetch(environment) { {} }["app_name"]
    @@app_name ||= config_hash.fetch(DEFAULT_ENV) { {} }["app_name"]
    @@app_name ||= ENV[APP_NAME]
    fail AppNameMissing, "app_name is not configured. See documentation for more information" unless @@app_name
    @@app_name
  end

  def self.namify(appname, sep = "_")
    return unless appname.is_a?(String)
    return unless appname.length > 0

    # Turn unwanted chars into the separator
    appname = appname.dup
    appname.gsub!(/[^a-z0-9\-_]+/i, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      appname.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      appname.gsub!(/^#{re_sep}|#{re_sep}$/, "")
    end
    appname.downcase
  end

  # Return a logger for the supplied class or class_name
  def self.[](klass)
    Sapience::Logger.new(klass)
  end

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
  #     Default: Sapience.config.default_level
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
  #   Sapience.add_appender(:stream, io: STDOUT)
  #
  #   # Send all logging output to a file
  #   Sapience.add_appender(:stream, file_name: 'logfile.log')
  #
  #   # Send all logging output to a file and only :info and above to standard output
  #   Sapience.add_appender(:stream, file_name: 'logfile.log')
  #   Sapience.add_appender(:stream, io: STDOUT, level: :info)
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
  #   Sapience.config.default_level = :debug
  #   Sapience.add_appender(:wrapper, logger: log)
  #
  #   logger = Sapience['Example']
  #   logger.info "Hello World"
  #   logger.debug("Login time", user: 'Joe', duration: 100, ip_address: '127.0.0.1')
  def self.add_appender(appender, options = {}, _deprecated_level = nil, &_block)
    fail ArgumentError, "options should be a hash" unless options.is_a?(Hash)
    options = options.dup.deep_symbolize_keyz!
    appender_class = constantize_symbol(appender)
    validate_appender!(appender_class)

    appender       = appender_class.new(options)
    @@appenders << appender

    # Start appender thread if it is not already running
    Sapience::Logger.start_appender_thread
    Sapience.logger = appender if appender.is_a?(Sapience::Appender::Stream)
    Sapience.metrics = appender if appender.is_a?(Sapience::Appender::Datadog)
    appender
  end

  def self.validate_appender!(appender)
    return if known_appenders.include?(appender)

    fail NotImplementedError,
      "Unknown appender '#{appender}'. Supported appenders are (#{known_appenders.join(", ")})"
  end

  def self.known_appenders
    @_known_appenders ||= Sapience::Subscriber.descendants
  end

  # Examples:
  #   Sapience.add_appenders(
  #     { file: { io: STDOUT } },
  #     { sentry: { dsn: "https://app.getsentry.com/" } },
  #   )
  def self.add_appenders(*appenders)
    appenders.flatten.compact.each do |appender|
      appender.each do |name, options|
        add_appender(name, options)
      end
    end
  end

  # Remove an existing appender
  # Currently only supports appender instances
  # TODO: Make it possible to remove appenders by type
  # Maybe create a concurrent collection that allows this by inheriting from concurrent array.
  def self.remove_appender(appender)
    @@appenders.delete(appender)
  end

  # Remove specific appenders or all existing
  def self.remove_appenders(appenders = @@appenders)
    appenders.each do |appender|
      remove_appender(appender)
    end
  end

  # Returns [Sapience::Subscriber] a copy of the list of active
  # appenders for debugging etc.
  # Use Sapience.add_appender and Sapience.remove_appender
  # to manipulate the active appenders list
  def self.appenders
    @@appenders.clone
  end

  def self.metrics=(metrics)
    @@metrics = metrics
  end

  def self.metrics
    @@metrics ||= nil
  end

  def self.logger=(logger)
    @@logger = Sapience::Logger.logger = logger
  end

  def self.logger
    @@logger ||= Sapience::Logger.logger
  end

  def self.test_exception(level = :error)
    fail Sapience::TestException, "Sapience Test Exception"
  rescue Sapience::TestException => ex
    Sapience[self].public_send(level, ex)
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

  # If the tag being supplied is definitely a string then this fast
  # tag api can be used for short lived tags
  def self.fast_tag(tag)
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
    new_tags                       = tags.flatten.collect(&:to_s).reject(&:empty?)
    t                              = Thread.current[:sapience_tags]
    Thread.current[:sapience_tags] = t.nil? ? new_tags : t.concat(new_tags)
    new_tags
  end

  def self.clear_tags!
    Thread.current[:sapience_tags] = []
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
  #   Sapience.config.default_level = :info
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
    current_index                     = Thread.current[:sapience_silence]
    Thread.current[:sapience_silence] = Sapience.config.level_to_index(new_level)
    yield
  ensure
    Thread.current[:sapience_silence] = current_index
  end

  reset_appenders!

  def self.log_executor_class
    constantize_symbol(config.log_executor, "Concurrent")
  end

  def self.constantize_symbol(symbol, namespace = "Sapience::Appender")
    class_name = "#{namespace}::#{symbol.to_sym.camelize}"
    constantize(class_name)
  end

  def self.constantize(class_name)
    return class_name unless class_name.is_a?(String)
    if RUBY_VERSION.to_i >= 2
      Object.const_get(class_name)
    else
      class_name.split("::").inject(Object) { |o, name| o.const_get(name) } # rubocop:disable SingleLineBlockParams
    end
  rescue NameError
    raise UnknownClass, "Could not find class: #{class_name}."
  end

  def self.root
    @_root ||= Gem::Specification.find_by_name("sapience").gem_dir
  end
end
