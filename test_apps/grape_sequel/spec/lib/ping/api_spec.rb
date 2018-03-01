# frozen_string_literal: true
require "spec_helper"
require "rack/test"

describe Ping::API do
  include Rack::Test::Methods

  def app
    Ping::API
  end

  context "GET /api/posts" do
    let(:logger) { Grape::API.logger }

    specify do
      get "/api/posts", {}, "CONTENT-TYPE" => "application/json"
      expect(last_response.body).to match(/PONG/)
    end

    # describe "ActiveSupport::Notifications" do
    #   let(:metrics) { Sapience.metrics }
    #   let(:tags) { %w(method:get format:json path:/api/ping status:200) }
    #   before do
    #     Sapience.configure { |c| c.app_name = "grape" }
    #   end
    #   specify do
    #     expect(metrics).to receive(:increment).with("grape.request", tags: tags)
    #     expect(metrics).to receive(:timing).with("grape.request.time", kind_of(Float), tags: tags)
    #     get "/api/ping", {}, "CONTENT-TYPE" => "application/json"
    #   end
    # end

    it "logs 200" do
      expect(logger).to receive(:info).with(
        method:       "GET",
        request_path: "/api/posts",
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

      get "/api/posts", {}, "CONTENT-TYPE" => "application/json"
    end
  end
end
