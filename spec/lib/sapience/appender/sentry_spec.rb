require "spec_helper"
describe Sapience::Appender::Sentry do
  before do
    @appender = Sapience::Appender::Sentry.new(:trace)
    @message = "AppenderRavenTest log message"
    Sapience.config.backtrace_level = :error
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
      @appender.send(level, @message)
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
      @appender.send(level, @message, error)
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
      @appender.send(level, @message)
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
      @appender.send(level, @message, error)
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
end
