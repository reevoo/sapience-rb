module Sapience
  class Rails < ::Rails::Engine
    ::Rails::Application::Bootstrap.initializers.delete_if { |i| i.name == :initialize_logger }
    initializer :initialize_logger, group: :all do
      # TODO: Is this really needed?
      # Existing loggers are ignored because servers like trinidad supply their
      # own file loggers which would result in duplicate logging to the same log file
      # ::Rails.logger = config.logger = begin
      #   Sapience[::Rails]
      # end

      # Replace Rails loggers
    end
  end
end
