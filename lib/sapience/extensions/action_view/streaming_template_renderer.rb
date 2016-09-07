# Log actual exceptions, not a string representation

class ActionView::StreamingTemplateRenderer # rubocop:disable ClassAndModuleChildren
  class Body
    private

    alias_method :log_error_original, :log_error

    def log_error(exception) #:nodoc:
      ActionView::Base.logger.fatal(exception)
    end
  end
end
