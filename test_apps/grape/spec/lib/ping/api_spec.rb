require "spec_helper"
require "rack/test"

describe Ping::API do
  include Rack::Test::Methods

  def app
    Ping::API
  end

  context "GET /api/ping" do
    let(:logger) { Grape::API.logger }

    specify do
      get "/api/ping"
      expect(last_response.body).to match(/PONG/)
    end

    it "logs something" do
      expect(logger).to receive(:info).with(
        method:       "GET",
        request_path: "/api/ping",
        format:       "json",
        status:       200,
        class_name:   "Ping::API",
        action:       "index",
        host:         "example.org",
        ip:           "127.0.0.1",
        ua:           nil,
        tags:         [],
        params:       {},
        runtimes:     a_hash_including(
                        total: kind_of(Float),
                        view:  kind_of(Float),
                        db:    kind_of(Float),
                      ),
      )

      get "/api/ping"
    end

    context "no routes defined" do
      it "logs something" do
        expect(logger).to receive(:info).with(
          method:       "GET",
          request_path: "/api/404",
          format:       "json",
          status:       404,
          class_name:   "Ping::API",
          action:       "index",
          host:         "example.org",
          ip:           "127.0.0.1",
          ua:           nil,
          tags:         [],
          params:       {},
          runtimes:     a_hash_including(
                          total: kind_of(Float),
                          view:  kind_of(Float),
                          db:    kind_of(Float),
                        ),
        )

        get "/api/404"
      end
    end
  end
end
