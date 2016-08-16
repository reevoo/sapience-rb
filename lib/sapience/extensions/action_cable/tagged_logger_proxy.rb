class ActionCable::Connection::TaggedLoggerProxy # rubocop:disable ClassAndModuleChildren
  module Inclusions
    def tag(logger, &block)
      current_tags = tags - logger.tags
      logger.tagged(*current_tags, &block)
    end
  end

  include Inclusions
end
