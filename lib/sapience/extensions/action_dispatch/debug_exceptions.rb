# Log actual exceptions, not a string representation

class ActionDispatch::DebugExceptions # rubocop:disable ClassAndModuleChildren
  private

  undef_method :log_error

  def log_error(_request, wrapper)
    ActiveSupport::Deprecation.silence do
      ActionController::Base.logger.fatal(wrapper.exception)
    end
  end
end
