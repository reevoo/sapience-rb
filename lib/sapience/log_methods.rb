# frozen_string_literal: true
module Sapience
  module LogMethods
    def trace(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:trace, message, payload, exception, &block)
    end

    def debug(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:debug, message, payload, exception, &block)
    end

    def info(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:info, message, payload, exception, &block)
    end

    def warn(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:warn, message, payload, exception, &block)
    end

    def error(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:error, message, payload, exception, &block)
    end

    def fatal(message = nil, payload = nil, exception = nil, &block)
      log_with_level(:fatal, message, payload, exception, &block)
    end

    def log_with_level(level, message = nil, payload = nil, exception = nil, &block)
      index = level_to_index(level)
      if level_index <= index
        log_internal(level, index, message, payload, exception, &block)
        true
      else
        false
      end
    end

    def error!(message = nil, payload = nil, exception = nil, &block)
      log_with_exception(:error, message, payload, exception, &block)
    end

    def fatal!(message = nil, payload = nil, exception = nil, &block)
      log_with_exception(:fatal, message, payload, exception, &block)
    end

    def log_with_exception(level, message = nil, payload = nil, exception = nil, &block)
      log_with_level(level, message, payload, exception, &block)
      Sapience.capture_exception(exception, payload) if exception
      Sapience.capture_exception(message, payload) if message.is_a?(Exception)
      Sapience.capture_exception(payload, message: message) if payload.is_a?(Exception)
      true
    end

    def trace?
      level_index <= 0
    end

    def debug?
      level_index <= 1
    end

    def info?
      level_index <= 2
    end

    def warn?
      level_index <= 3
    end

    def error?
      level_index <= 4
    end

    def fatal?
      level_index <= 5
    end

    def measure_trace(message, params = {}, &block)
      measure(:trace, message, params, &block)
    end
    alias benchmark_trace measure_trace

    def measure_debug(message, params = {}, &block)
      measure(:debug, message, params, &block)
    end
    alias benchmark_debug measure_debug

    def measure_info(message, params = {}, &block)
      measure(:info, message, params, &block)
    end
    alias benchmark_info measure_info

    def measure_warn(message, params = {}, &block)
      measure(:warn, message, params, &block)
    end
    alias benchmark_warn measure_warn

    def measure_error(message, params = {}, &block)
      measure(:error, message, params, &block)
    end
    alias benchmark_error measure_error

    def measure_fatal(message, params = {}, &block)
      measure(:fatal, message, params, &block)
    end
    alias benchmark_fatal measure_fatal

    # Dynamically supply the log level with every measurement call
    def measure(level, message, params = {}, &block)
      index = Sapience.config.level_to_index(level)
      if level_index <= index
        measure_internal(level, index, message, params, &block)
      else
        yield params if block
      end
    end

    alias benchmark measure

    def level_to_index(level)
      Sapience.config.level_to_index(level)
    end
  end
end
