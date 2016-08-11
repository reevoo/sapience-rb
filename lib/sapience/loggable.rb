module Sapience
  # rubocop:disable TrivialAccessors
  module Loggable
    def self.included(base)
      base.class_eval do
        # Returns [Sapience::Logger] class level logger
        def self.logger
          @sapience ||= Sapience[self]
        end

        # Replace instance class level logger
        def self.logger=(logger)
          @sapience = logger
        end

        # Returns [Sapience::Logger] instance level logger
        def logger
          @sapience ||= self.class.logger
        end

        # Replace instance level logger
        def logger=(logger)
          @sapience = logger
        end
      end
    end
  end
  # rubocop:enable TrivialAccessors
end
