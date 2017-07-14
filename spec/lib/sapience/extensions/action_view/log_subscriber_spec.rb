# frozen_string_literal: true
require "spec_helper"
require "sapience/extensions/action_view/log_subscriber"

describe Sapience::Extensions::ActionView::LogSubscriber do
  describe "#info" do
    let(:message) { "Test Message" }
    let(:logger) { Sapience[described_class] }

    before do
      allow(subject).to receive(:logger).and_return(logger)
    end

    specify do
      expect(logger).to receive(:debug).with(message).and_yield
      subject.info(message) do
        1 + 1
      end
    end
  end
end
