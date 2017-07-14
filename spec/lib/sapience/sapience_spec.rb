# frozen_string_literal: true
require "spec_helper"

describe Sapience do
  let(:sentry_options) do
    { dsn: "https://getsentry.com:443" }
  end
  let(:error_handler) do
    { sentry: sentry_options }
  end

  describe ".root" do
    its(:root) do
      is_expected.to eq(Gem::Specification.find_by_name("sapience").gem_dir)
    end
  end

  describe ".add_appender" do
    subject(:add_appender) { described_class.add_appender(appender, options) }

    context "unknown class" do
      let(:appender) { :statsd }
      let(:options) { {} }

      specify do
        expect { add_appender }.to raise_error(Sapience::UnknownClass, /Could not find/)
      end
    end

    context "unknown appender" do
      let(:appender) { :logger }
      let(:options) { {} }

      specify do
        expect { add_appender }.to raise_error(NotImplementedError, /Unknown appender/)
      end
    end

    context "when options is not a Hash" do
      let(:appender) { :stream }
      let(:options) { 1 }
      specify { expect { add_appender }.to raise_error(ArgumentError, "options should be a hash") }
    end

    context "when appender is :stream" do
      let(:appender) { :stream }

      context "and options has :io key present" do
        let(:options) do
          {
            io:        STDOUT,
            formatter: :color,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::Stream) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Color) }
      end

      context "and options has :file_name key present" do
        let(:options) do
          {
            file_name: "log/sapience.log",
            formatter: :json,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::Stream) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Json) }
      end
    end
  end

  describe ".config" do
    subject(:config) { described_class.config }

    it { is_expected.to be_a(Sapience::Configuration) }

    context "returns 'default' when no environment is provided" do
      before { allow(described_class).to receive(:environment).and_return("unknown") }
      its(:default_level) do
        is_expected.to eq(:info)
      end
    end
  end

  describe ".environment" do
    subject { described_class }

    context "when SAPIENCE_ENV is set" do
      let(:env) { "sapience" }
      before do
        allow(ENV).to receive(:fetch).with(Sapience::SAPIENCE_ENV).and_return(env)
      end

      its(:environment) do
        is_expected.to eq("sapience")
      end
    end

    context "when RAILS_ENV is set" do
      let(:env) { "integration" }
      before do
        allow(ENV).to receive(:fetch).with(Sapience::SAPIENCE_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RAILS_ENV).and_return(env)
      end

      its(:environment) do
        is_expected.to eq("integration")
      end
    end

    context "when RACK_ENV is set" do
      let(:env) { "ci" }
      before do
        allow(ENV).to receive(:fetch).with(Sapience::SAPIENCE_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RAILS_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RACK_ENV).and_return(env)
      end

      its(:environment) do
        is_expected.to eq("ci")
      end
    end

    context "when Rails respond to .env" do
      let(:env) { "fudge" }
      before do
        allow(ENV).to receive(:fetch).with(Sapience::SAPIENCE_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RAILS_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RACK_ENV).and_yield
        allow(Rails).to receive(:env).and_return(env)
      end

      its(:environment) do
        is_expected.to eq("fudge")
      end
    end

    context "when no other environment is found" do
      let(:env) { "default" }
      before do
        allow(ENV).to receive(:fetch).with(Sapience::SAPIENCE_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RAILS_ENV).and_yield
        allow(ENV).to receive(:fetch).with(Sapience::RACK_ENV).and_yield
        stub_const("Rails", double(:Rails, sub: "whatever"))
      end

      its(:environment) do
        is_expected.to eq("default")
      end
    end
  end

  describe ".app_name" do
    subject { described_class }

    context "when APP_NAME environment variable is set" do
      let(:app) { "my_app" }
      before do
        allow(ENV).to receive(:[]).with(Sapience::APP_NAME).and_return(app)
      end

      its(:app_name) do
        is_expected.to eq("my_app")
      end

      it "sets the app_name in config" do
        subject.app_name
        expect(Sapience.config.app_name).to eq(app)
      end
    end

    context "when APP_NAME has prohibited characters" do
      let(:app) { "RSpec R0x'n Ro!!5" }
      before do
        allow(ENV).to receive(:[]).with(Sapience::APP_NAME).and_return(app)
      end

      its(:app_name) do
        is_expected.to eq("RSpec R0x'n Ro!!5")
      end
    end

    context "when delegating to config.app_name" do
      let(:app) { nil }
      let(:config) { instance_spy(Sapience::Configuration, app_name: app) }

      before do
        allow(ENV).to receive(:[]).with(Sapience::APP_NAME).and_yield
        allow(Sapience).to receive(:config).and_return(config)
      end

      context "when config.app_name is set" do
        let(:app) { "test_app" }
        before do
          allow(Sapience.config_hash).to receive(:fetch).and_call_original
          allow(Sapience.config_hash).to receive(:fetch).with(Sapience::DEFAULT_ENV).and_return("app_name" => app)
        end

        its(:app_name) do
          is_expected.to eq("test_app")
        end
      end

      context "when no other app_name is found" do
        before do
          allow(ENV).to receive(:[]).with(Sapience::APP_NAME).and_return(nil)
        end
        specify do
          expect { described_class.app_name }
            .to raise_error(
              Sapience::AppNameMissing,
              "app_name is not configured. See documentation for more information",
            )
        end
      end
    end
  end

  describe ".configure" do
    let(:app_name) { "my_app" }
    context "when configure(force: false)" do
      let(:config) do
        instance_spy(Sapience::Configuration, app_name: app_name, error_handler: error_handler)
      end
      let(:stream_options) do
        { io: STDOUT }
      end
      let(:stream_appender) do
        { stream: stream_options }
      end
      let(:appenders) { [stream_appender] }

      before do
        allow(config).to receive(:appenders).and_return(appenders)
        allow(described_class).to receive(:config).and_return(config)
      end

      context "when some appenders exist before call" do
        before do
          Sapience.add_appender(:stream, io: STDERR, level: :info)
        end

        it "removes previously added appenders" do
          expect(described_class.appenders.size).to eq(1)
          described_class.configure do |c|
            expect(c).to eq(config)
          end
          expect(described_class.appenders.size).to eq(1)
        end
      end

      context "when no appenders exist before call" do
        before do
          expect(described_class)
            .to receive(:add_appender)
            .with(:stream, stream_options)
            .and_call_original
        end

        context "when provided a block" do
          it "adds all configured appenders" do
            described_class.configure(force: false) do |c|
              expect(c).to eq(config)
            end
            expect(described_class.appenders.size).to eq(1)
          end
        end

        context "when no block given" do
          it "adds all configured appenders" do
            described_class.configure(force: false)
            expect(described_class.configure).to eq(config)
            expect(described_class.appenders.size).to eq(1)
          end
        end
      end
    end

    context "when configure(force: true)" do
      before do
        Sapience.configure { |c| c.app_name = app_name }
      end
      specify do
        expect do
          Sapience.configure(force: true) do |config|
            config.default_level = :fatal
            config.backtrace_level = :error
            config.appenders = [
              { stream: { io: STDOUT, level: :info } },
              { stream: { io: STDERR, level: :error } },
              { stream: { io: STDOUT, level: :fatal } },
            ]
          end
        end.to change { Sapience.appenders.size }.by(2)
      end
    end

    context "when no block given" do
      it "adds all configured appenders" do
        Sapience.configure { |c| c.app_name = app_name }
        expect(described_class.configure).to be_a(Sapience::Configuration)
      end
    end
  end

  describe ".logger" do
    specify do
      expect(described_class.logger).to be_a(Sapience::Logger)
    end
  end

  describe ".metrics" do
    specify do
      expect(described_class.metrics).to be_a(Sapience::Metrics::Datadog)
    end

    context "when metics section specified in config" do
      before do
        allow(described_class.config).to receive(:metrics).and_return(datadog: { url: Sapience::DEFAULT_STATSD_URL })
      end

      specify do
        expect(described_class.metrics).to be_a(Sapience::Metrics::Datadog)
      end

      context "with invalid parameters" do
        before do
          allow(described_class.config).to receive(:metrics).and_return(invalid: { url: Sapience::DEFAULT_STATSD_URL })
        end

        specify do
          expect { described_class.metrics }.to raise_error(Sapience::UnknownClass)
        end
      end

      context "with missing parameters" do
        before do
          allow(described_class.config).to receive(:metrics).and_return(nil)
        end

        specify do
          expect { described_class.metrics }.to raise_error(Sapience::MissingConfiguration)
        end
      end
    end
  end

  describe ".metrics=" do
    TestMetrics = Class.new
    let!(:test_metrics) { TestMetrics.new }
    specify do
      described_class.metrics = test_metrics
      expect(described_class.metrics).not_to be_a(Sapience::Metrics::Datadog)
    end
  end

  describe ".error_handler" do
    specify do
      expect(Sapience.logger)
        .to receive(:warn).with("Error handler is not configured. See documentation for more information.")
      expect(described_class.error_handler).to be_a(Sapience::ErrorHandler::Silent)
    end

    context "when error_handler section specified in config" do
      before do
        allow(described_class.config).to receive(:error_handler).and_return(error_handler)
      end

      specify do
        expect(described_class.error_handler).to be_a(Sapience::ErrorHandler::Sentry)
      end


      context "with wrong parameters" do
        before do
          allow(described_class.config).to receive(:error_handler).and_return(uknown: {})
        end

        specify do
          expect { described_class.error_handler }.to raise_error(Sapience::UnknownClass)
        end
      end
    end
  end

  describe ".error_handler=" do
    TestErrorHandler = Class.new
    let!(:test_error_handler) { TestErrorHandler.new }
    specify do
      described_class.error_handler = test_error_handler
      expect(described_class.error_handler).to be_a(TestErrorHandler)
    end
  end

  describe ".capture_exception" do
    let(:sentry) { Sapience::ErrorHandler::Sentry.new(dsn: "https://foobar:443@sentry.io/00000") }
    let(:some_exception) { double(:some_exception) }
    let(:payload) do
      { test: "data" }
    end

    before do
      Sapience.error_handler = sentry
    end

    specify do
      expect(sentry).to receive(:capture_exception).with(some_exception, payload)
      described_class.capture_exception(some_exception, payload)
    end
  end

  describe ".capture_message" do
    let(:sentry) { Sapience::ErrorHandler::Sentry.new(dsn: "https://foobar:443@sentry.io/00000") }
    let(:message) { "test message" }
    let(:payload) do
      { test: "data" }
    end

    before do
      Sapience.error_handler = sentry
    end

    specify do
      expect(sentry).to receive(:capture_message).with(message, payload)
      described_class.capture_message(message, payload)
    end
  end

  describe ".test_exception" do
    # TODO: This test is flaky
    specify do
      Sapience.error_handler = Sapience::ErrorHandler::Sentry.new(dsn: "https://foobar:443@sentry.io/00000")
      expect(Raven).to receive(:capture_type) do |exception, _context|
        expect(exception).to be_a_kind_of(Sapience::TestException)
        expect(exception.message).to eq("Sapience Test Exception")
      end.and_return(true)

      described_class.test_exception
    end
  end
end
