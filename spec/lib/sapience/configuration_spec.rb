require "spec_helper"
require "logger"

describe Sapience::Configuration do
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
