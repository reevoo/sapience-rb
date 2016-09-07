# Patch ActiveModelSerializers logger
if defined?(ActiveModelSerializers)
  ActiveModelSerializers.logger = Sapience[ActiveModelSerializers]

  require "active_model_serializers/logging"

  module ActiveModelSerializers::Logging # rubocop:disable ClassAndModuleChildren
    private

    alias_method :orig_tag_logger, :tag_logger

    def tag_logger(*tags, &block)
      logger.tagged(*tags, &block)
    end
  end
end
