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
      before { allow(described_class).to receive(:environment).and_return(described_class::DEFAULT_ENV) }
      its(:default_level) do
        is_expected.to eq(:info)
      end
    end
  end

  describe ".environment" do
    subject { described_class }

    context "when RAILS_ENV is set" do
      let(:env) { "integration" }
      before do
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_return(env)
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end

    context "when RACK_ENV is set" do
      let(:env) { "ci" }
      before do
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_yield
        allow(ENV).to receive(:fetch).with("RACK_ENV").and_return(env)
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end

    context "when Rails respond to .env" do
      let(:env) { "fudge" }
      before do
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_yield
        allow(ENV).to receive(:fetch).with("RACK_ENV").and_yield
        allow(Rails).to receive(:env).and_return(env)
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end

    context "when no other environment is found" do
      let(:env) { "default" }
      before do
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_yield
        allow(ENV).to receive(:fetch).with("RACK_ENV").and_yield
        stub_const("Rails", double(:Rails, sub: 'fuck'))
      end

      its(:environment) do
        is_expected.to eq(env)
      end
    end
  end

  describe ".configure" do
    context "when configure(force: false)" do
      let(:config) do
        instance_spy(Sapience::Configuration)
      end
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
        allow(config).to receive(:appenders).and_return(appenders)
        allow(described_class).to receive(:config).and_return(config)
        expect(described_class).to receive(:add_appender).with(:file, file_options).and_call_original
        expect(described_class).to receive(:add_appender).with(:sentry, sentry_options).and_call_original
      end

      context "when provided a block" do
        it "adds all configured appenders" do
          described_class.configure(force: false) do |c|
            expect(c).to eq(config)
          end
          expect(described_class.appenders.size).to eq(2)
        end
      end

      context "when no block given" do
        it "adds all configured appenders" do
          described_class.configure(force: false)
          expect(described_class.configure).to eq(config)
          expect(described_class.appenders.size).to eq(2)
        end
      end
    end

    context "when configure(force: true)" do
      before { Sapience.configure }
      specify do
        expect do
          Sapience.configure(force: true) do |config|
            config.default_level = :fatal
            config.backtrace_level = :error
            config.appenders = [
              { file: { io: STDOUT, level: :info } },
              { file: { io: STDERR, level: :error } },
              { file: { io: STDOUT, level: :fatal } },
            ]
          end
        end.to change { Sapience.appenders.size }.by(3)
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
