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

    context 'when rails is loaded' do
      # TODO: This spec is a little flaky
      it "requires rails extensions" do
        expect(Kernel).to receive(:require).with("sapience/extensions/action_cable/tagged_logger_proxy")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/live")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_dispatch/debug_exceptions")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_view/streaming_template_renderer")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_job/logging")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_model_serializers/logging")
        expect(Kernel).to receive(:require).with("sapience/extensions/rack/logger")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/active_record/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/rack/logger_info_as_debug")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_view/log_subscriber")
        expect(Kernel).to receive(:require).with("sapience/extensions/action_controller/log_subscriber_processing")
        described_class.configure
      end
    end

    context 'when rails is not loaded' do
      before(:all) do
        Object.send(:remove_const, "ActionCable") if defined?(ActionCable)
        ActionController.send(:remove_const, "Live") if defined?(ActionController::Live)
        ActionDispatch.send(:remove_const, "DebugExceptions") if defined?(ActionDispatch::DebugExceptions)
        ActionView::StreamingTemplateRenderer.send(:remove_const, "Body") if defined?(ActionView::StreamingTemplateRenderer::Body)
        Object.send(:remove_const, "ActiveJob") if defined?(ActiveJob)
        Object.send(:remove_const, "ActiveModelSerializers") if defined?(ActiveModelSerializers)
        Rails::Rack.send(:remove_const, "Logger") if defined?(Rails::Rack::Logger)
        Rails.send(:remove_const, "Rack") if defined?(Rails::Rack)
        Object.send(:remove_const, "ActionController") if defined?(ActionController)
        ActiveRecord.send(:remove_const, "LogSubscriber") if defined?(ActiveRecord::LogSubscriber)
        ActionView.send(:remove_const, "LogSubscriber") if defined?(ActionView::LogSubscriber)
      end

      it 'does not require rails extensions' do
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_cable/tagged_logger_proxy")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/live")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_dispatch/debug_exceptions")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/streaming_template_renderer")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_job/logging")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_model_serializers/logging")
        # expect(Kernel).not_to receive(:require).with("sapience/extensions/rack/logger")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_record/log_subscriber")
        # expect(Kernel).not_to receive(:require).with("sapience/extensions/rack/logger_info_as_debug")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber_processing")
        described_class.configure
      end
    end
  end
end
