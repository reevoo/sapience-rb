# frozen_string_literal: true
require "grape"
require "grape/api"
require "sapience/grape"
require "active_support/notifications"

class PageNotFound < RuntimeError; end

module Ping
  class API < ::Grape::API
    format :json
    use Sapience::Extensions::Grape::Middleware::Logging, logger: Grape::API.logger
    prefix :api

    # This block is required in all apps that use Sapience.
    # Logging middleware is never called if we dont have a catch-all route.
    route :any, "*path" do
      error!({ error: "No route found", status: 404 }, 404)
    end

    desc "Returns pong."
    get :ping do
      { ping: "PONG" }
    end

    get "not-found" do
      fail PageNotFound, "Customer experience not enabled"
    end

    get :err do
      nil.no_method
      # the goal here is to raise a realistic 500 error, in this case NoMethodError
    end
  end
end
