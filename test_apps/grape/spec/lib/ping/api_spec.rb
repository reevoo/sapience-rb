require "spec_helper"

describe Ping::API do
  include Rack::Test::Methods

  def app
    Ping::API
  end

  context "GET /api/ping" do
    specify do
      get "/api/ping"
      expect(last_response.body).to match(/PONG/)
    end
  end
end
