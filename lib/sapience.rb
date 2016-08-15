require "sapience/version"
require "sapience/sapience"

# @formatter:off

require "sapience/concerns/compatibility"

require "sapience/formatters/base"
require "sapience/formatters/raw"
require "sapience/formatters/default"
require "sapience/formatters/color"
require "sapience/formatters/json"

require "sapience/configuration"
require "sapience/ansi_colors"
require "sapience/core_ext/hash"
require "sapience/core_ext/thread"
require "sapience/base"
require "sapience/log"
require "sapience/logger"
require "sapience/loggable"
require "sapience/subscriber"

require "sapience/appender/file"
require "sapience/appender/sentry"
require "sapience/appender/wrapper"
require "sapience/appender/statsd"

# @formatter:on

# Close and flush all appenders at exit, waiting for outstanding messages on the queue
# to be written first
at_exit do
  # Cannot call #close since test frameworks use at_exit to run loaded tests
  Sapience.flush
end
