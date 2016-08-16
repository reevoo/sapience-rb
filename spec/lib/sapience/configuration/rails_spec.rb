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
      require "action_controller/railtie"
      require "action_mailer/railtie"
      require "action_view/railtie"
      # require "action_cable/engine"
    end

    context 'when rails is loaded' do
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
      before do
        Object.send(:remove_const, ActionCable)
        Object.send(:remove_const, ActionController::Live)
        Object.send(:remove_const, ActionDispatch::DebugExceptions)
        Object.send(:remove_const, ActionView::StreamingTemplateRenderer::Body)
        Object.send(:remove_const, ActiveJob)
        Object.send(:remove_const, ActiveModelSerializers)
        Object.send(:remove_const, Rails::Rack::Logger)
        Object.send(:remove_const, ActionController)
        Object.send(:remove_const, ActiveRecord::LogSubscriber)
        Object.send(:remove_const, Rails::Rack::Logger)
        Object.send(:remove_const, ActionView::LogSubscriber)
        Object.send(:remove_const, ActionView::LogSubscriber)
      end

      it 'does not require rails extensions' do
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_cable/tagged_logger_proxy")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/live")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_dispatch/debug_exceptions")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/streaming_template_renderer")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_job/logging")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_model_serializers/logging")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/rack/logger")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/active_record/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/rack/logger_info_as_debug")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_view/log_subscriber")
        expect(Kernel).not_to receive(:require).with("sapience/extensions/action_controller/log_subscriber_processing")
        described_class.configure
      end
    end
  end
end
