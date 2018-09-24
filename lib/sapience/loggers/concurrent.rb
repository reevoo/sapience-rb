# Sapience::Loggers::Concurrent is a class wrapping all methods necessary for integration with concurrent-ruby gem .
module Sapience
  module Loggers
    class Concurrent < Sapience::Logger

      def initialize(level = nil, filter = nil)
        super("Concurrent", level, filter)
      end

      # *call* method is expected to be defined for all Concurrent.global_logger instances
      # see https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent/concern/logging.rb#L25
      def call(level, progname, message, &block)
        log(level, message, progname, &block)
      end
    end
  end
end
