# frozen_string_literal: true
require "grape"
require "grape/api"
require "sapience/grape"
require "active_support/notifications"

require_relative "./db"

module Ping
  class API < ::Grape::API
    format :json
    use Sapience::Extensions::Grape::Middleware::Logging, logger: Grape::API.logger
    prefix :api

    route :any, "*path" do
      error!({ error: "No route found", status: 404 }, 404)
    end

    desc "Returns posts."
    get :posts do
      { posts: Ping.db[:posts].to_a }
    end

    get :err do
      fail "it failed!"
    end
  end
end
