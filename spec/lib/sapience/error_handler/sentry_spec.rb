require "spec_helper"

describe Sapience::ErrorHandler::Sentry do
  subject { described_class.new(options) }

  let(:level) { :trace }
  let(:dsn) { "https://foobar:443" }
  let(:message) { "Test message" }
  force_config(backtrace_level: :error)
  let(:options) do
    {
      level: level,
      dsn: dsn,
    }
  end

  describe "configuration" do
    context "when options is a valid hash" do
      it { is_expected.to be_valid }
    end

    context "when options is not a hash" do
      let(:options) { 12_345 }
      specify do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when dsn is invalid uri" do
      let(:dsn) { "poop" }
      it { is_expected.to_not be_valid }
    end
  end

  describe "#configure_sentry" do
    context "when configured" do
      before do
        allow(subject).to receive(:configured?).and_return(true)
      end

      specify do
        expect(Raven).to_not receive(:configure)
        subject.configure_sentry
      end
    end

    context "when not configured" do
      let(:raven_configuration) { instance_double(Raven::Configuration) }

      specify do
        allow(subject).to receive(:configured?).and_return(false)
        expect(raven_configuration).to receive(:server=).with(dsn)
        expect(raven_configuration).to receive(:tags=).with(environment: Sapience.environment)
        expect(raven_configuration).to receive(:logger=).with(kind_of(Sapience::Logger))
        expect(Raven).to receive(:configure).and_yield(raven_configuration)
        subject.configure_sentry
      end

      specify do
        expect { subject.configure_sentry }.to change { subject.configured? }.to(true)
      end
    end
  end

  describe "#capture_exception" do
    let(:exception) do
      instance_double(NotImplementedError, message: "Test Class not implemented")
    end
    let(:payload) do
      {
        test: "data",
      }
    end

    specify do
      expect(Raven).to receive(:capture_type) do |exception, options|
        expect(exception.message).to eq("Test Class not implemented")
        expect(options).to eq(extra: payload)
      end.and_return(true)

      subject.capture_exception(exception, payload)
    end

    context "when payload as Sentry Raven options" do
      let(:payload) do
        {
          extra: { another_test: "other_data" },
        }
      end

      specify do
        expect(Raven).to receive(:capture_type) do |exception, options|
          # expect(exception).to be_a_kind_of(NotImplementedError)
          expect(exception.message).to eq("Test Class not implemented")
          expect(options).to eq(payload)
        end.and_return(true)

        subject.capture_exception(exception, payload)
      end
    end
  end
end
