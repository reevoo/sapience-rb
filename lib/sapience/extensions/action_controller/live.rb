# Log actual exceptions, not a string representation

module ActionController::Live # rubocop:disable ClassAndModuleChildren
  def log_error(exception)
    logger.fatal(exception)
  end
end
