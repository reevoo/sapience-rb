module Sapience
  class Configuration
    class Grape
      def self.configure
        Grape::API.send(:include, Sapience::Loggable)
      end
    end
  end
end
