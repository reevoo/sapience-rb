module Sapience
  # Log Struct
  #
  #   Structure for holding all log entries. We're using a struct because we want it to be fast and lightweight.
  #
  # level
  #   Log level of the supplied log call
  #   :trace, :debug, :info, :warn, :error, :fatal
  #
  # thread_name
  #   Name of the thread in which the logging call was called
  #
  # name
  #   Class name supplied to the logging instance
  #
  # message
  #   Text message to be logged
  #
  # payload
  #   Optional Hash or Ruby Exception object to be logged
  #
  # time
  #   The time at which the log entry was created
  #
  # duration
  #   The time taken to complete a measure call
  #
  # tags
  #   Any tags active on the thread when the log call was made
  #
  # level_index
  #   Internal index of the log level
  #
  # exception
  #   Ruby Exception object to log
  #
  # metric [Object]
  #   Object supplied when measure_x was called
  #
  # backtrace [Array<String>]
  #   The backtrace_level captured at source when the log level >= Sapience.config.backtrace_level
  #
  # metric_amount [Numeric]
  #   Used for numeric or counter metrics.
  #   For example, the number of inquiries or, the amount purchased etc.

  # rubocop:disable LineLength
  Log = Struct.new(:level, :thread_name, :name, :message, :payload, :time, :duration, :tags, :level_index, :exception, :metric, :backtrace, :metric_amount) do
    MAX_EXCEPTIONS_TO_UNWRAP = 5
    MILLISECONDS_IN_SECOND =   1_000
    MILLISECONDS_IN_MINUTE =  60_000
    MILLISECONDS_IN_HOUR = 3_600_000
    MILLISECONDS_IN_DAY = 86_400_000

    # Returns [String] the exception backtrace including all of the child / caused by exceptions
    def backtrace_to_s
      trace = ""
      each_exception do |exception, i|
        if i == 0
          trace << (exception.backtrace || []).join("\n")
        else
          trace << "\nCause: #{exception.class.name}: #{exception.message}\n#{(exception.backtrace || []).join("\n")}"
        end
      end
      trace
    end

    # Returns [String] duration of the log entry as a string
    # Returns nil if their is no duration
    def duration_to_s
      return unless duration
      format((duration < 10.0 ? "%.3fms" : "%.1fms"), duration)
    end

    # Returns [String] the duration in human readable form
    def duration_human # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity
      return nil unless duration
      days, ms    = duration.divmod(MILLISECONDS_IN_DAY)
      hours, ms   = ms.divmod(MILLISECONDS_IN_HOUR)
      minutes, ms = ms.divmod(MILLISECONDS_IN_MINUTE)
      seconds, ms = ms.divmod(MILLISECONDS_IN_SECOND)

      str = ""
      str << "#{days}d" if days > 0
      str << " #{hours}h" if hours > 0
      str << " #{minutes}m" if minutes > 0
      str << " #{seconds}s" if seconds > 0
      str << " #{ms}ms" if ms > 0

      if days > 0 || hours > 0 || minutes > 0
        str.strip
      else
        if seconds >= 1.0
          format "%.3fs", duration / MILLISECONDS_IN_SECOND.to_f
        else
          duration_to_s
        end
      end
    end

    # Returns [String] single character upper case log level
    def level_to_s
      level.to_s[0..0].upcase
    end

    # Returns [String] the available process info
    # Example:
    #    18934:thread 23 test_logging.rb:51
    def process_info(thread_name_length = 30)
      file, line = file_name_and_line(true)
      file_name  = " #{file}:#{line}" if file

      format "#{$PROCESS_ID}:%.#{thread_name_length}s#{file_name}", thread_name
    end

    CALLER_REGEXP = /^(.*):(\d+).*/

    # Extract the filename and line number from the last entry in the supplied backtrace
    def extract_file_and_line(stack, short_name = false)
      match = CALLER_REGEXP.match(stack.first)
      [short_name ? File.basename(match[1]) : match[1], match[2].to_i]
    end

    # Returns [String, String] the file_name and line_number from the backtrace supplied
    # in either the backtrace or exception
    def file_name_and_line(short_name = false) # rubocop:disable CyclomaticComplexity
      return unless backtrace || (exception && exception.backtrace)
      stack = backtrace || exception.backtrace
      extract_file_and_line(stack, short_name) if stack && stack.size > 0
    end

    # Strip the standard Rails colorizing from the logged message
    def cleansed_message
      message.to_s.gsub(/(\e(\[([\d;]*[mz]?))?)?/, "").strip
    end

    # Return the payload in text form
    # Returns nil if payload is missing or empty
    def payload_to_s
      payload.inspect if payload?
    end

    # Returns [true|false] whether the log entry has a payload
    def payload?
      !(payload.nil? || (payload.respond_to?(:empty?) && payload.empty?))
    end

    # Return the Time as a formatted string
    # Ruby MRI supports micro seconds
    # DEPRECATED
    def formatted_time
      format("#{time.strftime("%Y-%m-%d %H:%M:%S")}.%06d", time.usec)
    end

    # Returns [Hash] representation of this log entry
    def to_h(host = Sapience.config.host, app_name = Sapience.app_name) # rubocop:disable AbcSize, CyclomaticComplexity, PerceivedComplexity, LineLength
      # Header
      h               = {
        name:        name,
        pid:         $PROCESS_ID,
        thread:      thread_name,
        time:        time,
        level:       level,
        level_index: level_index,
      }
      h[:host]     = host if host
      h[:app_name] = app_name if app_name
      file, line   = file_name_and_line
      if file
        h[:file] = file
        h[:line] = line.to_i
      end

      # Tags
      h[:tags] = tags if tags && (tags.size > 0)

      # Duration
      if duration
        h[:duration_ms] = duration
        h[:duration]    = duration_human
      end

      # Log message
      h[:message] = cleansed_message if message

      # Payload
      if payload
        if payload.is_a?(Hash)
          h.merge!(filtered_payload)
        else
          h[:payload] = payload
        end
      end

      # Exceptions
      if exception
        root = h
        each_exception do |exception, i|
          name       = i == 0 ? :exception : :cause
          root[name] = {
            name:        exception.class.name,
            message:     exception.message,
            stack_trace: exception.backtrace,
          }
          root = root[name]
        end
      end

      # Metric
      h[:metric] = metric if metric
      h
    end

    private

    # Call the block for exception and any nested exception
    def each_exception # rubocop:disable AbcSize, PerceivedComplexity, CyclomaticComplexity
      # With thanks to https://github.com/bugsnag/bugsnag-ruby/blob/6348306e44323eee347896843d16c690cd7c4362/lib/bugsnag/notification.rb#L81
      depth      = 0
      exceptions = []
      ex         = exception
      while !ex.nil? && !exceptions.include?(ex) && exceptions.length < MAX_EXCEPTIONS_TO_UNWRAP
        exceptions << ex
        yield(ex, depth)

        depth += 1
        ex =
          # continued_exception is only used by REXML
          # original_exception is deprecated in Rails 5+
          # Not worth testing to thoroughly?
          if ex.respond_to?(:cause) && ex.cause
            ex.cause
          elsif ex.respond_to?(:continued_exception) && ex.continued_exception
            ex.continued_exception
          elsif ex.respond_to?(:original_exception) && ex.original_exception
            ex.original_exception
          end
      end
    end

    def filtered_payload
      payload[:params][:password] = '[FILTERED]' if payload[:params] && payload[:params][:password]
      payload[:params][:password_confirmation] = '[FILTERED]' if payload[:params] && payload[:params][:password_confirmation]
      payload
    end
  end
  # rubocop:enable LineLength
end
