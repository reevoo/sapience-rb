# frozen_string_literal: true
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
      get "/api/ping", {}, "CONTENT-TYPE" => "application/json"
      expect(last_response.body).to match(/PONG/)
    end

    describe "ActiveSupport::Notifications" do
      let(:metrics) { Sapience.metrics }
      let(:tags) { %w(method:get format:json path:/api/ping status:200) }
      before do
        Sapience.configure { |c| c.app_name = "grape" }
      end
      specify do
        expect(metrics).to receive(:increment).with("grape.request", tags: tags)
        expect(metrics).to receive(:timing).with("grape.request.time", kind_of(Float), tags: tags)
        get "/api/ping", {}, "CONTENT-TYPE" => "application/json"
      end
    end

    it "logs 200" do
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

      get "/api/ping", {}, "CONTENT-TYPE" => "application/json"
    end

    context "no routes defined" do
      it "logs 404" do
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

        get "/api/404", {}, "CONTENT-TYPE" => "application/json"
      end
    end

    context "when raising a custom not_found exception" do
      it "logs 404" do
        expect(logger).to receive(:info).with(
          method:       "GET",
          request_path: "/api/not-found",
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

        get "/api/not-found", {}, "CONTENT-TYPE" => "application/json"
      end
    end

    context "500 in endpoint" do
      it "logs 500" do
        expect(logger).to receive(:info).with(
            method:       "GET",
            request_path: "/api/err",
            format:       "json",
            status:       500,
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

        expect do
          get "/api/err", {}, "CONTENT-TYPE" => "application/json"
        end.to raise_error(NoMethodError)
      end
    end
  end
end
