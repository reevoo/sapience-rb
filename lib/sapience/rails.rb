module Sapience
  class Rails < ::Rails::Engine
    ENV['RAILS_ENV']
    Rails.env
    Sapience.configure do |c|
      c.default_level           = config.log_level
      c.default_backtrace_level = config.log_level
      c.application             = ::Rails.application.class.name
      c.appenders               = [
        { file: { io: STDOUT, formatter: ENV['SAPIENCE_FORMATTER'] } },
        { statsd: { url: ENV['STATSD_URL'] } },
        { sentry: { dsn: ENV['RAVEN_DSN'] } },
      ]
     c.appenders << {  }
    end

    ::Rails.logger = Sapience.logger
    ::Rails::Application::Bootstrap.initializers.delete_if { |i| i.name == :initialize_logger }
    initializer :initialize_logger, group: :all do
      config = ::Rails.application.config
      # Set the default log level based on the Rails config
      Sapience.config.default_level = config.log_level

      # Existing loggers are ignored because servers like trinidad supply their
      # own file loggers which would result in duplicate logging to the same log file
      ::Rails.logger = config.logger = begin
        Sapience.config.appenders.each do |appenders|
          appenders.each do |appender, options|
            Sapience.add_appender(appender, options)
          end
        end
        # TODO: Should not use .first
        Sapience::Logger.logger = Sapience.appenders.first
        Sapience[::Rails]
      rescue StandardError => exc
        # If not able to log to file, log to standard error with warning level only
        Sapience.config.default_level = :warn

        Sapience::Logger.logger = Sapience::Appender::File.new(io: STDERR)
        Sapience.add_appender(:file, io: STDERR)

        logger = Sapience[::Rails]
        logger.warn(
          "Rails Error: Unable to access log file. " \
            "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed.",
          exc,
        )
        logger
      end

      # Replace Rails loggers
      [:active_record, :action_controller, :action_mailer, :action_view].each do |name|
        ActiveSupport.on_load(name) { include Sapience::Loggable }
      end
      ActiveSupport.on_load(:action_cable) { self.logger = Sapience["ActionCable"] }
    end
  end
end
