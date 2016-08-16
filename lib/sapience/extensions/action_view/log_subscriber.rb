class ActionView::LogSubscriber # rubocop:disable ClassAndModuleChildren
  def info(message = nil, &block)
    debug(message, &block)
  end

  def info?
    debug?
  end
end
