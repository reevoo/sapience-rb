# frozen_string_literal: true
class ActionCable::Connection::TaggedLoggerProxy # rubocop:disable ClassAndModuleChildren
  alias orig_tag tag

  def tag(logger, &block)
    current_tags = tags - logger.tags
    logger.tagged(*current_tags, &block)
  end
end
