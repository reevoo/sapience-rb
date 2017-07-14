# frozen_string_literal: true
# Log actual exceptions, not a string representation

class ActionDispatch::DebugExceptions # rubocop:disable ClassAndModuleChildren
  private

  alias orig_log_error log_error

  def log_error(_request, wrapper)
    ActiveSupport::Deprecation.silence do
      ActionController::Base.logger.fatal(wrapper.exception)
    end
  end
end
