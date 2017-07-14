# frozen_string_literal: true
require "spec_helper"
require "rails/rack/logger"
require "sapience/extensions/rails/rack/logger_info_as_debug"

describe Rails::Rack::Logger do
  subject { described_class.new(double) }
  let(:logger) { subject.send(:logger) }

  describe "#info" do
    let(:message) { "test" }
    specify do
      expect(logger).to receive(:debug).with(message)
      logger.info(message)
    end
  end

  describe "#info?" do
    specify do
      expect(logger).to receive(:debug?).and_call_original
      logger.info?
    end
  end
end
