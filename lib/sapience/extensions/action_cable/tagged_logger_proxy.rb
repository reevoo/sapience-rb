class ActionCable::Connection::TaggedLoggerProxy # rubocop:disable ClassAndModuleChildren
  alias_method :orig_tag, :tag

  def tag(logger, &block)
    current_tags = tags - logger.tags
    logger.tagged(*current_tags, &block)
  end
end
