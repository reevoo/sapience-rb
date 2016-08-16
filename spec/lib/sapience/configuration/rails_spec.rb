require "spec_helper"

describe Sapience::Configuration::Rails do
  describe ".configure" do
    specify do
      expect(Rails).to receive(:logger=).with(a_kind_of(Sapience::Logger))
      expect(ActiveSupport).to receive(:on_load).with(:active_record)
      expect(ActiveSupport).to receive(:on_load).with(:action_controller)
      expect(ActiveSupport).to receive(:on_load).with(:action_mailer)
      expect(ActiveSupport).to receive(:on_load).with(:action_view)
      expect(ActiveSupport).to receive(:on_load).with(:action_cable)
      described_class.configure
    end

    before do
      require "rails/all"
      require "active_model/railtie"
      require "active_job/railtie"
      require "active_record/railtie"
      require "active_record/log_subscriber"
      require "action_controller/railtie"
      require "action_mailer/railtie"
      require "action_view/railtie"
      require "active_model_serializers"
      require "action_cable/engine"
      require "rails/rack"
      require "action_cable/connection/tagged_logger_proxy"
      require "action_controller/metal"
      require "action_controller/metal/live"
    end

    context "when rails is loaded" do
      it "requires rails extensions" do
        expect(Kernel).to receive(:require).with("sapience/extensions/action_cable/tagged_logger_proxy")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/live")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_dispatch/debug_exceptions")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_view/streaming_template_renderer")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_job/logging")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_model_serializers/logging")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_record/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/rails/rack/logger")
        expect(Kernel).to receive(:require).with("sapience/extensions/rails/rack/logger_info_as_debug")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_view/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/log_subscriber_processing")
        described_class.configure
      end
    end

    context "when rails is not loaded" do
      before do
        hide_const("ActionCable")
        hide_const("ActionController::Live")
        hide_const("ActionDispatch::DebugExceptions")
        hide_const("ActionView::StreamingTemplateRenderer::Body")
        hide_const("ActiveJob")
        hide_const("ActiveModelSerializers")
        hide_const("Rails::Rack::Logger")
        hide_const("Rails::Rack")
        hide_const("ActionController")
        hide_const("ActiveRecord::LogSubscriber")
        hide_const("ActionView::LogSubscriber")
      end

      it "does not require rails extensions" do
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_cable/tagged_logger_proxy")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/live")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_dispatch/debug_exceptions")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/streaming_template_renderer")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_job/logging")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_model_serializers/logging")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_record/log_subscriber")
        # TODO: Find a way to test the commented lines below
        # expect(Kernel).not_to receive(:require).with("sapience/extensions/rails/rack/logger")
        # expect(Kernel).not_to receive(:require).with("sapience/extensions/rails/rack/logger_info_as_debug")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber_processing")
        described_class.configure
      end
    end
  end
end
