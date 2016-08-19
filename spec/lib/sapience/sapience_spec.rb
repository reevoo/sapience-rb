require "spec_helper"

describe Sapience do
  describe ".add_appender" do
    subject(:add_appender) { described_class.add_appender(appender, options) }

    after do
      Sapience.remove_appender(subject) if options.is_a?(Hash)
    end

    context "when options is not a Hash" do
      let(:appender) { :file }
      let(:options) { 1 }
      specify { expect { add_appender }.to raise_error(ArgumentError, "options should be a hash") }
    end

    context "when appender is :file" do
      let(:appender) { :file }

      context "and options has :io key present" do
        let(:options) do
          {
            io:        STDOUT,
            formatter: :color,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::File) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Color) }
      end

      context "and options has :file_name key present" do
        let(:options) do
          {
            file_name: "log/sapience.log",
            formatter: :json,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::File) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Json) }
      end
    end

    context "when :statsd key is present" do
      let(:appender) { :datadog }
      let(:options) do
        {
          url: "udp://localhost:2222",
        }
      end

      it { is_expected.to be_a(Sapience::Appender::Datadog) }
    end

    context "when :sentry key is present" do
      let(:appender) { :sentry }
      let(:options) do
        {
          level: :info,
          dsn: "https://foobar:443",
        }
      end

      it { is_expected.to be_a(Sapience::Appender::Sentry) }
    end
  end

  describe ".config" do
    subject(:config) { described_class.config }

    it { is_expected.to be_a(Sapience::Configuration) }

    context "returns 'default' when no environment is provided" do
      before { allow(described_class).to receive(:environment).and_return(nil) }
      its(:default_level) do
        is_expected.to eq(:info)
      end
    end
  end

  describe ".environment" do
    subject { described_class }

    context "when RAILS_ENV is set" do
      let(:env) { "integration" }
      before { allow(ENV).to receive(:fetch).with("RAILS_ENV").and_return(env) }

      its(:environment) do
        is_expected.to eq(env)
      end
    end

    context "when RACK_ENV is set" do
      let(:env) { "ci" }
      before do
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_call_original
        allow(ENV).to receive(:fetch).with("RACK_ENV").and_return(env)
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end

    context "when Rails respond to .env " do
      let(:env) { "fudge" }
      before do
        allow(Rails).to receive(:env).and_return(env)
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end
  end

  describe ".configure" do
    let(:file_options) do
      { io: STDOUT }
    end
    let(:file_appender) do
      { file: file_options }
    end
    let(:sentry_options) do
      { dsn: "https://getsentry.com:443" }
    end
    let(:sentry_appender) do
      { sentry: sentry_options }
    end
    let(:appenders) { [file_appender, sentry_appender] }

    before do
      allow(described_class.config).to receive(:appenders).and_return(appenders)
      expect(described_class).to receive(:add_appender).with(:file, file_options)
      expect(described_class).to receive(:add_appender).with(:sentry, sentry_options)
    end

    context "when provided a block" do
      it "adds all configured appenders" do
        described_class.configure do |config|
          expect(config).to be_a(Sapience::Configuration)
        end
      end
    end

    context "when no block given" do
      it "adds all configured appenders" do
        expect(described_class.configure).to be_a(Sapience::Configuration)
      end
    end
  end

  describe ".logger" do
    specify do
      expect(described_class.logger).to be_a(Sapience::Appender::File)
    end
  end

  describe ".metrix" do
    specify do
      expect(described_class.metrix).to be_a(Sapience::Appender::Datadog)
    end
  end
end
