# Log actual exceptions, not a string representation

class ActionDispatch::DebugExceptions # rubocop:disable ClassAndModuleChildren
  module Inclusions
    private

    def log_error(_request, wrapper)
      ActiveSupport::Deprecation.silence do
        ActionController::Base.logger.fatal(wrapper.exception)
      end
    end
  end

  include Inclusions
end
