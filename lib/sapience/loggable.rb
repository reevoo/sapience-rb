module Sapience
  module Loggable
    def self.included(base)
      base.class_exec do
        include SemanticLogger::Loggable
      end
    end
  end
end
