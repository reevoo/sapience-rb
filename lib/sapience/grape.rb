require "sapience"
require "sapience/extensions/grape/timings"
require "sapience/extensions/grape/middleware/logging"

module Grape
  class API
    extend Sapience::Descendants
  end
end

module Sapience
  class Grape
    Sapience.configure
    ::Grape::API.send(:include, Sapience::Loggable)
  end
end
