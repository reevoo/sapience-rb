require "sapience/version"
require "sapience/sapience"

# @formatter:off
module Sapience
  autoload :Configuration,      "sapience/configuration"
  autoload :AnsiColors,         "sapience/ansi_colors"
  autoload :Thread,             "sapience/core_ext/thread"
  autoload :Base,               "sapience/base"
  autoload :Log,                "sapience/log"
  autoload :Logger,             "sapience/logger"
  autoload :Loggable,           "sapience/loggable"
  autoload :Subscriber,         "sapience/subscriber"

  module Appender
    autoload :File,             "sapience/appender/file"
    autoload :Sentry,           "sapience/appender/sentry"
    autoload :Wrapper,          "sapience/appender/wrapper"
    autoload :Statsd,           "sapience/appender/statsd"
  end

  module Concerns
    autoload :Compatibility,    "sapience/concerns/compatibility"
  end

  module Formatters
    autoload :Base,             "sapience/formatters/base"
    autoload :Color,            "sapience/formatters/color"
    autoload :Default,          "sapience/formatters/default"
    autoload :Json,             "sapience/formatters/json"
    autoload :Raw,              "sapience/formatters/raw"
    autoload :Syslog,           "sapience/formatters/syslog"
  end

end
# @formatter:on

# Close and flush all appenders at exit, waiting for outstanding messages on the queue
# to be written first
at_exit do
  # Cannot call #close since test frameworks use at_exit to run loaded tests
  Sapience.flush
end
