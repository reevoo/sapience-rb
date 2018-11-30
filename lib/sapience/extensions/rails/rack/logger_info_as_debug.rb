# frozen_string_literal: true
require "rails/rack/logger"

# For rails > 3, drop rack Started message to debug level message
# For rails == 3, patch the logger to remove the log lines
# that say: 'Started GET / for 192.168.2.1...'
class Rails::Rack::Logger # rubocop:disable ClassAndModuleChildren

  if Rails::VERSION::MAJOR == 3 && ::Sapience.config.silent_rack
    def call_app(*args)
      env = args.last
      @app.call(env)
    ensure
      ActiveSupport::LogSubscriber.flush_all!
    end
  end

  private

  module Extensions
    def info(*args, &block)
      debug(*args, &block)
    end

    def info?
      debug?
    end
  end

  alias orig_logger logger

  def logger
    @logger ||= begin
      logger = Sapience["Rails"]
      logger.extend(Extensions)
      logger
    end
  end

end
