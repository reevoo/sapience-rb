# frozen_string_literal: true
require "spec_helper"
require "sapience/loggers/concurrent"

describe Sapience::Loggers::Concurrent do
  describe ".new" do
    subject { described_class.new }

    its(:name) { is_expected.to eq("Concurrent") }

    context ".call" do
      let(:level) { 1 }
      let(:progname) { "progname" }
      let(:message) { "message" }

      it "calls log method with parameters in specific order" do
        expect(subject).to receive(:log).with(level, message, progname)
        subject.call(1, progname, message)
      end
    end
  end
end
