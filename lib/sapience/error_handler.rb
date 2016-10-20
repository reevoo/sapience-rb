module Sapience
  class ErrorHandler
    extend Sapience::Descendants

    def capture_exception(_exception, _options = {})
      fail NotImplementedError
    end

    def capture_message(_message, _options = {})
      fail NotImplementedError
    end
  end
end
