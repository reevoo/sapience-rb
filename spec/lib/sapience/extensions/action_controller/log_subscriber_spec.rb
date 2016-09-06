require "spec_helper"
# require "sapience/extensions/action_controller/log_subscriber"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sapience/rails"

describe Sapience::Extensions::ActionController::LogSubscriber do
  class TestController < ::ActionController::Base
  end

  let(:sapience_tags) { %w(appname rails staging) }
  let(:log_tags) { %w(other tags) }
  let(:tags) { log_tags + sapience_tags }
  let(:user_params) do
    {
      "username" => "testuser",
      "email" => "test@user.com",
    }
  end

  let(:payload) do
    {
      method: "GET",
      format: "json",
      path: "/api/test?key=value",
      status: 200,
      db_runtime: 50,
      view_runtime: 100,
      params: {
        "action" => "index",
        "controller" => "test_controller",
        "user" => user_params,
      },
      controller: "test_controller",
    }
  end
  let(:logger) { Sapience[described_class]  }
  let(:duration) { 1_000 }
  let(:event) do
    instance_spy(ActiveSupport::Notifications::Event, payload: payload, duration: duration)
  end

  before(:each) do
    Sapience.config.host = "example.com"
    logger.tags = sapience_tags
    ActionController::Base.logger = logger
  end

  describe "#process_action" do
    specify do
      expected = {
        method: "GET",
        request_path: "/api/test",
        format: "json",
        status: 200,
        controller: "test_controller",
        action: "index",
        host: "example.com",
        route: "test_controller#index",
        message: "Completed #index",
        tags: sapience_tags,
        params: { "user" => user_params },
        runtimes: {
          total: 1_000.0,
          view: 100.0,
          db: 50.0,
        },
      }
      expect(logger).to receive(:info).with(expected)
      subject.process_action(event)
    end
  end
end
