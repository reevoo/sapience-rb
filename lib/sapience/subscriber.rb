# frozen_string_literal: true
# Abstract Subscriber
#
#   Abstract base class for appender and metrics subscribers.
module Sapience
  class Subscriber < Sapience::Base
    # Every logger has its own formatter
    attr_accessor :formatter
    attr_writer :app_name, :host

    extend Sapience::Descendants

    # Returns the current log level if set, otherwise it logs everything it receives
    def level
      @level || :trace
    end

    # A subscriber should implement flush if it can.
    def flush
      # NOOP
    end

    # TODO: Implement this mehtod in all appenders
    # TODO: Output relevant message when appender isn't valid
    # TODO: Check this valid? method before using appender, output above error message if not valid?
    # TODO: Wait with adding appenders until they are needed solve this by below
    # TODO: Implement possibility of finding and deleting appenders by env
    def valid?
      fail NotImplementedError, "needs to be implemented in appender"
    end

    # TODO: Implement a format string with class name and interesting values
    # see:
    #   - https://www.rubysteps.com/articles/2015/customize-your-ruby-classes-with-to-s-and-inspect/
    #   - http://stackoverflow.com/questions/9524698/override-to-s-while-keeping-output-of-inspect
    #   - http://stackoverflow.com/questions/2625667/why-do-this-ruby-object-have-both-to-s-and-inspect-methods-that-appear-to-do-the
    def to_s
      name
    end

    def name
      self.class.name
    end

    # A subscriber should implement close if it can.
    def close
      # NOOP
    end

    # Returns [Sapience::Formatters::Default] formatter default for this subscriber
    def default_formatter
      Sapience::Formatters::Default.new
    end

    # Allow app_name to be set globally or per subscriber
    def app_name
      @app_name || Sapience.app_name
    end

    # Allow host name to be set globally or per subscriber
    def host
      @host || Sapience.config.host
    end

    private

    # Initializer for Abstract Class Sapience::Subscriber
    #
    # Parameters
    #   level: [:trace | :debug | :info | :warn | :error | :fatal]
    #     Override the log level for this subscriber.
    #     Default: :error
    #
    #   formatter: [Object|Proc]
    #     An instance of a class that implements #call, or a Proc to be used to format
    #     the output from this subscriber
    #     Default: Use the built-in formatter (See: #call)
    #
    #   filter: [Regexp|Proc]
    #     RegExp: Only include log messages where the class name matches the supplied.
    #     regular expression. All other messages will be ignored.
    #     Proc: Only include log messages where the supplied Proc returns true
    #           The Proc must return true or false.
    #
    #   host: [String]
    #     Name of this host to appear in log messages.
    #     Default: Sapience.config.host
    #
    #   app_name: [String]
    #     Name of this app_name to appear in log messages.
    #     Default: Sapience.app_name
    def initialize(options = {}, &block)
      # Backward compatibility
      options     = { level: options } unless options.is_a?(Hash)
      options     = options.dup
      level       = options.delete(:level)
      filter      = options.delete(:filter)
      @formatter  = extract_formatter(options.delete(:formatter), &block)
      @app_name   = options.delete(:app_name)
      @host       = options.delete(:host)
      fail(ArgumentError, "Unknown options: #{options.inspect}") unless options.empty?

      # Subscribers don't take a class name, so use this class name if an subscriber
      # is logged to directly
      super(self.class, level, filter)
    end

    # Return the level index for fast comparisons
    # Returns the lowest level index if the level has not been explicitly
    # set for this instance
    def level_index
      @level_index || 0
    end

    # Return formatter that responds to call
    # Supports formatter supplied as:
    # - Symbol
    # - Hash ( Symbol => { options })
    # - Instance of any of Sapience::Formatters
    # - Proc
    # - Any object that responds to :call
    # - If none of the above apply, then the supplied block is returned as the formatter.
    # - Otherwise an instance of the default formatter is returned.
    # rubocop:disable CyclomaticComplexity, AbcSize, PerceivedComplexity
    def extract_formatter(formatter, &block)
      if formatter.is_a?(Symbol) || formatter.is_a?(String)
        Sapience.constantize_symbol(formatter, "Sapience::Formatters").new
      elsif formatter.is_a?(Hash) && !formatter.empty?
        fmt, options = formatter.first
        Sapience.constantize_symbol(fmt.to_sym, "Sapience::Formatters").new(options)
      elsif formatter.respond_to?(:call)
        formatter
      elsif block
        block
      elsif respond_to?(:call)
        self
      else
        default_formatter
      end
    end
    # rubocop:enable CyclomaticComplexity, AbcSize, PerceivedComplexity
  end
end
