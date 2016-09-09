# Patch ActiveModelSerializers logger

if defined?(ActiveModelSerializers)
  require "active_model_serializers/logging"

  module ActiveModelSerializers::Logging # rubocop:disable ClassAndModuleChildren
    def self.included(base)
      base.send(:include, Sapience::Loggable)
    end

    private

    alias_method :orig_tag_logger, :tag_logger

    def tag_logger(*tags, &block)
      logger.tagged(*tags, &block)
    end
  end

  ActiveModelSerializers.send(:include, Sapience::Loggable)
end
