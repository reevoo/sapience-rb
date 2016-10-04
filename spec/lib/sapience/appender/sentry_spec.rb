require "spec_helper"
describe Sapience::Appender::Sentry do
  let(:level) { :trace }
  let(:dsn) { "https://foobar:443" }
  let(:appender) { add_appender(options) }
  let(:message) { "AppenderRavenTest log message" }
  force_config(backtrace_level: :error)
  let(:options) do
    {
      level: level, dsn: dsn
    }
  end

  before { Sapience.configure { |c| c.app_name = "test_app" } }

  after { Sapience.remove_appenders }

  def add_appender(options = {})
    Sapience.add_appender(:sentry, options)
  end

  subject { appender }

  its(:name) do
    is_expected.to eq(described_class.name)
  end

  describe "#log" do
    let(:config) { instance_spy(Raven::Configuration) }
    let(:log) do
      LogFactory.build(
        level: :error,
        thread_name: "Test",
        name: "another",
        message: "My message",
        payload: {},
      )
    end
    it "configures tags for Raven" do
      expect(Raven).to receive(:configure).and_yield(config)
      expect(config).to receive(:dsn=).with(dsn)
      expect(config).to receive(:tags=).with(environment: "development")
      appender.log(log)
    end

    context "when dsn is empty string" do
      let(:appender) { add_appender(dsn: "") }
      specify do
        allow(Raven).to receive(:configure).and_yield(config)
        expect(config).not_to receive(:tags=)
        expect(config).not_to receive(:dsn=)
        appender.log(log)
      end
      its(:valid?) { is_expected.to eq(false) }
    end
  end

  shared_examples "capturing backtrace" do
    it "sends message" do
      expect(Raven)
        .to receive(:capture_message)
        .with(
          "AppenderRavenTest log message",
          a_hash_including(
            error_class: "Sapience::Appender::Sentry",
            error_message: "AppenderRavenTest log message",
            context: {
              pid: a_kind_of(Integer),
              thread: a_kind_of(String),
              time: a_kind_of(Time),
              level: level,
              level_index: a_kind_of(Integer),
              host: Sapience.config.host,
              app_name: Sapience.app_name,
              file: a_string_ending_with("example.rb"),
              line: 254,
            },
            backtrace: a_kind_of(Array),
          ),
        )
      appender.send(level, message)
    end

    it "sends exceptions" do
      error = RuntimeError.new("Oh no, Error.")
      expect(Raven)
        .to receive(:capture_exception)
        .with(
          error,
          a_hash_including(
            name: "Sapience::Appender::Sentry",
            message: "AppenderRavenTest log message",
            pid: a_kind_of(Integer),
            thread: a_kind_of(String),
            time: a_kind_of(Time),
            level: level,
            level_index: a_kind_of(Integer),
            host: Sapience.config.host,
            app_name: Sapience.app_name,
          ),
        )
      appender.send(level, message, error)
    end
  end


  shared_examples "capture without backtrace" do
    it "sends message" do
      expect(Raven)
        .to receive(:capture_message)
        .with(
          "AppenderRavenTest log message",
          a_hash_including(
            error_class: "Sapience::Appender::Sentry",
            error_message: "AppenderRavenTest log message",
            context: {
              pid: a_kind_of(Integer),
              thread: a_kind_of(String),
              time: a_kind_of(Time),
              level: level,
              level_index: a_kind_of(Integer),
              host: Sapience.config.host,
              app_name: Sapience.app_name,
            },
          ),
        )
      appender.send(level, message)
    end

    it "sends exceptions" do
      error = RuntimeError.new("Oh no, Error.")
      expect(Raven)
        .to receive(:capture_exception)
        .with(
          error,
          a_hash_including(
            name: "Sapience::Appender::Sentry",
            message: "AppenderRavenTest log message",
            pid: a_kind_of(Integer),
            thread: a_kind_of(String),
            time: a_kind_of(Time),
            level: level,
            level_index: a_kind_of(Integer),
            host: Sapience.config.host,
            app_name: Sapience.app_name,
          ),
        )
      appender.send(level, message, error)
    end
  end

  context "when level is debug" do
    let(:level) { :debug }

    it_behaves_like "capture without backtrace"
  end

  context "when level is :trace" do
    let(:level) { :trace }

    it_behaves_like "capture without backtrace"
  end

  context "when level is :info" do
    let(:level) { :info }

    it_behaves_like "capture without backtrace"
  end

  context "when level is :warn" do
    let(:level) { :warn }

    it_behaves_like "capture without backtrace"
  end

  context "when level is :error" do
    let(:level) { :error }

    it_behaves_like "capturing backtrace"
  end

  context "when level is :fatal" do
    let(:level) { :fatal }

    it_behaves_like "capturing backtrace"
  end

  context "when dsn is invalid uri" do
    subject { add_appender(dsn: "poop") }
    its(:valid?) { is_expected.to eq(false) }
  end
end
