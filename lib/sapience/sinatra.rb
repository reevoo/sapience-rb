# frozen_string_literal: true
require "sapience"
require "sapience/extensions/sinatra/timings"
require "sapience/extensions/sinatra/middleware/logging"

module Sinatra
  class Base
    extend Sapience::Descendants
  end
end

module Sapience
  class Sinatra
    Sapience.configure
    ::Sinatra::Base.send(:include, Sapience::Loggable)
  end
end
