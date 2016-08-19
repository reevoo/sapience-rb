require "sapience"
require "sapience/extensions/grape/timings"
require "sapience/extensions/grape/middleware/logging"

module Grape
  class API
    def self.descendants # :nodoc:
      descendants = []
      ObjectSpace.each_object(singleton_class) do |k|
        descendants.unshift k unless k == self
      end
      descendants
    end
  end
end

module Sapience
  class Grape
    Sapience.configure
    ::Grape::API.send(:include, Sapience::Loggable)
    ::Grape::API.descendants.each do |api|
      api.send(:use, Sapience::Extensions::Grape::Middleware::Logging, logger: Sapience[self])
    end
  end
end
