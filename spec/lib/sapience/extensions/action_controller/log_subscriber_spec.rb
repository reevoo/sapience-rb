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
  SapienceError = Class.new(StandardError)

  let(:sapience_tags) { %w(appname rails staging) }
  let(:log_tags) { %w(other tags) }
  let(:tags) { log_tags + sapience_tags }
  let(:user_params) do
    {
      "username" => "testuser",
      "email" => "test@user.com",
    }
  end
  let(:exception) { nil }
  let(:request_id) { SecureRandom.uuid }

  let(:success_payload) do
    {
      method: "GET",
      format: "json",
      exception: exception,
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
  let(:payload) { success_payload.dup }
  let(:logger) { Sapience[described_class] }
  let(:duration) { 1_000 }
  let(:event) do
    instance_spy(ActiveSupport::Notifications::Event, transaction_id: request_id, payload: payload, duration: duration)
  end
  let(:success_hash) do
    {
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
      request_id: request_id,
      params: { "user" => user_params },
      runtimes: {
        total: 1_000.0,
        view: 100.0,
        db: 50.0,
      },
    }
  end

  before(:each) do
    Sapience.config.host = "example.com"
    logger.tags = sapience_tags
    ActionController::Base.logger = logger
  end

  describe "#process_action" do
    let(:expected) { success_hash.dup }

    specify do
      expect(subject).to receive(:info).with(a_hash_including(expected))
      subject.process_action(event)
    end

    context "when logger.info? is false" do
      specify do
        allow(subject.logger).to receive(:info?).and_return(false)
        expect(subject.process_action(event)).to eq(nil)
      end
    end

    context "when payload has exception" do
      let(:exception) do
        begin
          fail SapienceError, "Error in sapience"
        rescue => e
          e
        end
      end

      let(:expected) do
        success_hash.dup.merge(
          status: 500,
          error: a_string_starting_with(
            "Error in sapience\n" \
            "Error in sapience\n" \
            "#{Sapience.root}/spec/lib/sapience/extensions/action_controller/log_subscriber_spec.rb",
          ),
        )
      end

      specify do
        expect(subject).to receive(:info).with(expected)
        subject.process_action(event)
      end
    end

    context "when actionpack version is 3" do
      before do
        stub_const("::ActionPack::VERSION::MAJOR", 3)
        stub_const("::ActionPack::VERSION::MINOR", 0)
        expect(::ActionPack::VERSION::MAJOR).to eq(3)
        expect(::ActionPack::VERSION::MINOR).to eq(0)
      end

      let(:payload) do
        success_payload.dup.merge(formats: ["html"])
      end

      let(:expected) do
        success_hash.dup.merge(format: "html")
      end

      specify do
        expect(subject).to receive(:info).with(expected)
        subject.process_action(event)
      end
    end
  end
end
