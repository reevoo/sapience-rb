require "spec_helper"
require "logger"

describe Sapience::Configuration do
  describe "#validate_log_executor!" do
    specify do
      expect { subject.validate_log_executor!(:invalid) }
        .to raise_error(Sapience::InvalidLogExecutor)
    end
  end

  describe "#log_level_active_record" do
    it "sets the default level to :info" do
      expect(Sapience.config.log_level_active_record).to eq(:info)
    end

    it "can override the default level" do
      Sapience.config.log_level_active_record = :debug
      expect(Sapience.config.log_level_active_record).to eq(:debug)
    end
  end

  describe "#level_to_index" do
    def level_to_index
      subject.level_to_index(level)
    end

    context "when level is nil" do
      let(:level) { nil }
      specify { expect(level_to_index).to eq(nil) }
    end

    context "when level is a symbol" do
      let(:level) { :info }
      specify { expect(level_to_index).to eq(2) }
    end

    context "when level is a string" do
      let(:level) { "TRACE" }
      specify { expect(level_to_index).to eq(0) }
    end

    context "when level is an integer" do
      context "when Logger::Severity is undefined" do
        before { hide_const("Logger::Severity") }
        let(:level) { 1 }
        specify { expect { level_to_index }.to raise_error(Sapience::UnkownLogLevel) }
      end

      context "when Logger::Severity is defined" do
        let(:level) { 1 }
        specify { expect(level_to_index).to eq(2) }

        context "when level is out of range" do
          let(:level) { 99 }
          specify { expect { level_to_index }.to raise_error(Sapience::UnkownLogLevel) }
        end
      end
    end

    context "when level is an object" do
      let(:level) { Object.new }
      specify { expect { level_to_index }.to raise_error(Sapience::UnkownLogLevel) }
    end
  end
end
