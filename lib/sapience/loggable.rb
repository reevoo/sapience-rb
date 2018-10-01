# frozen_string_literal: true
module Sapience
  module Loggable
    def self.included(base)
      base.send(:extend, Extensions)
    end

    # Returns [Sapience::Logger] instance level logger
    def logger
      @logger ||= self.class.logger
    end

    # Replace instance level logger
    def logger=(logger)
      @logger = logger
    end

    module Extensions
      # Returns [Sapience::Logger] class level logger
      def logger
        @logger ||= Sapience[self]
      end

      # Replace instance class level logger
      def logger=(logger)
        @logger = logger
      end
    end
  end

end
