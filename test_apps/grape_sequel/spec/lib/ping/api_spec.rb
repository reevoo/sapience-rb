# frozen_string_literal: true
require "spec_helper"
require "rack/test"
require "json"

describe Ping::API do
  include Rack::Test::Methods

  def app
    Ping::API
  end

  context "GET /api/posts" do
    let(:logger) { Grape::API.logger }

    before(:all) do
      Ping.db[:posts].insert(title: "Foo", body: "Foo body")
    end

    after(:all) do
      Ping.db[:posts].truncate
    end

    specify do
      get "/api/posts", {}, "CONTENT-TYPE" => "application/json"
      json = JSON.parse(last_response.body)
      expect(json["posts"].is_a?(Array)).to eq(true)
      expect(json["posts"][0]).to include("title" => "Foo", "body" => "Foo body")
    end

    it "logs 200" do
      expect(logger).to receive(:info) do |info|
        expect(info[:method]).to eq("GET")
        expect(info[:request_path]).to eq("/api/posts")
        expect(info[:status]).to eq(200)
        expect(info[:class_name]).to eq("Ping::API")
        expect(info[:action]).to eq("index")
        expect(info[:host]).to eq("example.org")
        expect(info[:ip]).to eq("127.0.0.1")
        expect(info[:ua]).to be_nil
        expect(info[:runtimes][:db]).to be > 0
        expect(info[:runtimes][:view]).to be > 0
        expect(info[:runtimes][:total]).to eq(info[:runtimes][:db] + info[:runtimes][:view])
      end

      get "/api/posts", {}, "CONTENT-TYPE" => "application/json"
    end
  end
end
