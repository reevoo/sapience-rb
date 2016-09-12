require "grape"
require "grape/api"
require "sapience/grape"

module Ping
  class API < ::Grape::API
    format :json
    use Sapience::Extensions::Grape::Middleware::Logging, logger: Sapience[self]
    prefix :api

    desc "Returns pong."
    get :ping do
      { ping: "PONG" }
    end
  end
end
