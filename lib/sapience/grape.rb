require "sapience"
require "sapience/extensions/grape/timings"
require "sapience/extensions/grape/middleware/logging"
require "sapience/extensions/grape/notifications"

module Grape
  class API
    extend Sapience::Descendants
  end
end

module Sapience
  class Grape
    Sapience.configure
    ::Grape::API.send(:include, Sapience::Loggable)
    Sapience::Extensions::Grape::Notifications.use
  end
end
