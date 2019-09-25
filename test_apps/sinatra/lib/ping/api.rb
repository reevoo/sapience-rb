# frozen_string_literal: true
require "sinatra/base"
require "sapience/sinatra"

module Ping
  class API < ::Sinatra::Base
    use Sapience::Extensions::Sinatra::Middleware::Logging, logger: Sinatra::Base.logger

    get "/ping" do
      { ping: "PONG" }
    end

    get "/err" do
      fail "it failed!"
    end

    get "/*" do
      status 404
    end
  end
end
