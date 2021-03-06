# frozen_string_literal: true
# Log actual exceptions, not a string representation

module ActionController::Live # rubocop:disable ClassAndModuleChildren
  undef_method :log_error
  def log_error(exception)
    logger.fatal(exception)
  end
end
