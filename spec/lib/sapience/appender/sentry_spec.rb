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

  after { Sapience.remove_appenders }

  def add_appender(options = {})
    Sapience.add_appender(:sentry, options)
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
              application: Sapience.config.application,
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
            application: Sapience.config.application,
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
              application: Sapience.config.application,
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
            application: Sapience.config.application,
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

  context "when dsn is missing" do
    specify do
      expect { add_appender }
        .to raise_error(ArgumentError, "Options need to have the key :dsn")
    end
  end

  context "when dsn is invalid uri" do
    specify do
      expect { add_appender(dsn: "poop") }
        .to raise_error(ArgumentError, "The :dsn key (poop) is not a valid URI")
    end
  end
end
