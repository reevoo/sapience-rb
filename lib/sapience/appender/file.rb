# File appender
#
#   Writes log messages to a file or open IO stream
#
module Sapience
  module Appender
    class File < Sapience::Subscriber

      # Create a File Logger appender instance.
      #
      # Parameters
      #  :file_name [String|IO]
      #    Name of file to write to.
      #    Or, an IO stream to which to write the log message to.
      #
      #  :level [:trace | :debug | :info | :warn | :error | :fatal]
      #    Override the log level for this appender.
      #    Default: Sapience.config.default_level
      #
      #  :formatter: [Object|Proc]
      #    An instance of a class that implements #call, or a Proc to be used to format
      #    the output from this appender
      #    Default: Use the built-in formatter (See: #call)
      #
      #  :filter [Regexp|Proc]
      #    RegExp: Only include log messages where the class name matches the supplied
      #    regular expression. All other messages will be ignored.
      #    Proc: Only include log messages where the supplied Proc returns true
      #          The Proc must return true or false.
      #
      # Example
      #    require 'sapience'
      #
      #    # Enable trace level logging
      #    Sapience.config.default_level = :info
      #
      #    # Log to screen
      #    Sapience.add_appender(:stream, io: STDOUT, formatter: :color)
      #
      #    # And log to a file at the same time
      #    Sapience::Logger.add_appender(:stream, file_name: 'application.log', formatter: :color)
      #
      #    logger = Sapience['test']
      #    logger.info 'Hello World'
      #
      # Example 2. To log all levels to file and only :info and above to screen:
      #
      #    require 'sapience'
      #
      #    # Enable trace level logging
      #    Sapience.config.default_level = :trace
      #
      #    # Log to screen but only display :info and above
      #    Sapience.add_appender(:stream, io: STDOUT, level: :info)
      #
      #    # And log to a file at the same time, including all :trace level data
      #    Sapience.add_appender(:stream, file_name: 'application.log')
      #
      #    logger =  Sapience['test']
      #    logger.info 'Hello World'
      # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity
      def initialize(options = {}, &block)
        unless options[:io] || options[:file_name]
          fail "Sapience::Appender::File missing mandatory parameter :file_name or :io"
        end

        opts = options.dup
        if (io = opts.delete(:io))
          @log = Sapience.constantize(io)
        else
          @file_name = opts.delete(:file_name)
          reopen
        end

        # Set the log level and formatter if supplied
        super(opts, &block)
      end
      # rubocop:enable AbcSize, CyclomaticComplexity, PerceivedComplexity

      # After forking an active process call #reopen to re-open
      # open the file handles etc to resources
      #
      # Note: This method will only work if :file_name was supplied
      #       on the initializer.
      #       If :io was supplied, it will need to be re-opened manually.
      def reopen
        return unless @file_name
        ensure_folder_exist

        @log      = open(@file_name, (::File::WRONLY | ::File::APPEND | ::File::CREAT))
        # Force all log entries to write immediately without buffering
        # Allows multiple processes to write to the same log file simultaneously
        @log.sync = true
        @log.set_encoding(Encoding::BINARY) if @log.respond_to?(:set_encoding)
        @log
      end

      def ensure_folder_exist
        return if ::File.exist?(@file_name)

        dir_name = ::File.dirname(@file_name)

        FileUtils.mkdir_p(dir_name)
      end

      # Pass log calls to the underlying Rails, log4j or Ruby logger
      #  trace entries are mapped to debug since :trace is not supported by the
      #  Ruby or Rails Loggers
      def log(log)
        return false unless should_log?(log)

        # Since only one appender thread will be writing to the file at a time
        # it is not necessary to protect access to the file with a semaphore
        # Allow this logger to filter out log levels lower than it's own
        @log.write(formatter.call(log, self) << "\n")
        true
      end

      # Flush all pending logs to disk.
      #  Waits for all sent documents to be writted to disk
      def flush
        @log.flush if @log.respond_to?(:flush)
      end

    end
  end
end
