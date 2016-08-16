# Patch ActiveModelSerializers logger
require "active_model_serializers/logging"

module ActiveModelSerializers::Logging # rubocop:disable ClassAndModuleChildren
  include Sapience::Loggable

  private

  alias_method :tag_logger_old, :tag_logger

  def tag_logger(*tags, &block)
    logger.tagged(*tags, &block)
  end
end
