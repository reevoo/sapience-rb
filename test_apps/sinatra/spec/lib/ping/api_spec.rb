# frozen_string_literal: true
require "spec_helper"
require "rack/test"

describe Ping::API do
  include Rack::Test::Methods

  def app
    Ping::API
  end

  context "GET /ping" do
    let(:logger) { Sinatra::Base.logger }

    specify do
      get "/ping", {}, "CONTENT-TYPE" => "application/json"
      expect(last_response.body).to match(/PONG/)
    end

    it "logs 200" do
      expect(logger).to receive(:info).with(
        method:       "GET",
        request_path: "/ping",
        route:        "GET /ping",
        status:       200,
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
      get "/ping", {}, "CONTENT-TYPE" => "application/json"
    end

    context "no routes defined" do
      it "logs 404" do
        expect(logger).to receive(:info).with(
          method:       "GET",
          request_path: "/404",
          route:        "GET /*",
          status:       404,
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

        get "/404", {}, "CONTENT-TYPE" => "application/json"
      end
    end

    context "500 in endpoint" do
      it "logs 500" do
        expect(logger).to receive(:info).with(
          method:       "GET",
          request_path: "/err",
          route:        "GET /err",
          status:       500,
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

        get "/err", {}, "CONTENT-TYPE" => "application/json"
      end
    end
  end
end
