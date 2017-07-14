# frozen_string_literal: true
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
    UnsupportedVersion = Class.new(Exception)
    if Gem.loaded_specs["grape"].version < Gem::Version.create("0.16.2")
      fail UnsupportedVersion, "Expecting grape version >= 0.16.2"
    end
    Sapience.configure
    ::Grape::API.send(:include, Sapience::Loggable)
    Sapience::Extensions::Grape::Notifications.use
  end
end
