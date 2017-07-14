# frozen_string_literal: true
require "sapience/version"
require "sapience/ansi_colors"
require "sapience/core_ext/hash"
require "sapience/core_ext/symbol"
require "sapience/core_ext/thread"
require "sapience/descendants"
require "sapience/log_methods"
require "sapience/appender"
require "sapience/metrics"
require "sapience/error_handler"
require "sapience/sapience"
require "sapience/extensions/notifications"

# @formatter:off

require "sapience/concerns/compatibility"

require "sapience/formatters/base"
require "sapience/formatters/raw"
require "sapience/formatters/default"
require "sapience/formatters/color"
require "sapience/formatters/json"

require "sapience/config_loader"
require "sapience/configuration"
require "sapience/base"
require "sapience/log"
require "sapience/logger"
require "sapience/loggable"
require "sapience/subscriber"

require "sapience/appender/stream"
require "sapience/appender/wrapper"
require "sapience/metrics/datadog"
require "sapience/error_handler/silent"
require "sapience/error_handler/sentry"

# @formatter:on

# Close and flush all appenders at exit, waiting for outstanding messages on the queue
# to be written first
at_exit do
  # Cannot call #close since test frameworks use at_exit to run loaded tests
  Sapience.flush
end
