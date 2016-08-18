# Log actual exceptions, not a string representation

class ActionView::StreamingTemplateRenderer # rubocop:disable ClassAndModuleChildren
  class Body
    private

    def log_error(exception) #:nodoc:
      ActionView::Base.logger.fatal(exception)
    end
  end
end
