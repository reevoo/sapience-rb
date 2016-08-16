# Log actual exceptions, not a string representation

class ActionView::StreamingTemplateRenderer # rubocop:disable ClassAndModuleChildren
  class Body
    module Inclusions
      private

      def log_error(exception) #:nodoc:
        ActionView::Base.logger.fatal(exception)
      end
    end

    include Inclusions
  end
end
