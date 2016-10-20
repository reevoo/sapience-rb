module Sapience
  class Metrics
    extend Sapience::Descendants

    def timing(_metric, _duration = 0, _options = {})
      fail NotImplementedError
    end

    def increment(_metric, _options = {})
      fail NotImplementedError
    end

    def decrement(_metric, _options = {})
      fail NotImplementedError
    end

    def histogram(_metric, _amount, _options = {})
      fail NotImplementedError
    end

    def gauge(_metric, _amount, _options = {})
      fail NotImplementedError
    end

    def count(_metric, _amount, _options = {})
      fail NotImplementedError
    end

    def time(_metric, _options = {}, &_block)
      fail NotImplementedError
    end

    def batch(&_block)
      fail NotImplementedError
    end

    def event(_title, _text, _options = {})
      fail NotImplementedError
    end
  end
end
