# Drop rack Started message to debug level message
class Rails::Rack::Logger # rubocop:disable ClassAndModuleChildren

  private

  module Extensions
    def info(*args, &block)
      debug(*args, &block)
    end

    def info?
      debug?
    end
  end

  alias_method :logger_original, :logger

  def logger
    @logger ||= begin
      logger = Sapience["Rails"]
      logger.extend(Extensions)
      logger
    end
  end

end
