require "spec_helper"

# rubocop:disable LineLength
describe Sapience::Concerns::Compatibility do
  force_config(default_level: :trace, backtrace_level: nil)
  let(:mock_logger) { MockLogger.new }
  let!(:appender) { Sapience.add_appender(:wrapper, logger: mock_logger) }
  let(:logger) { Sapience["CompatibilityTest"] }
  before do
    @thread_name = Thread.current.name
  end

  after { Sapience.remove_appenders }

  it "#add" do
    logger.add(Logger::INFO, "hello world", "progname") { "Data" }
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ I \[\d+:#{@thread_name}\] CompatibilityTest -- hello world -- Data -- \"progname\"/)
  end

  it "#log" do
    logger.log(Logger::FATAL, "hello world", "progname") { "Data" }
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ F \[\d+:#{@thread_name}\] CompatibilityTest -- hello world -- Data -- \"progname\"/)
  end

  it "#unknown" do
    logger.unknown("hello world") { "Data" }
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ E \[\d+:#{@thread_name}\] CompatibilityTest -- hello world -- Data/)
  end

  it "#unknown? as error?" do
    use_config(default_level: :error) do
      expect(logger.unknown?).to eq(true)
    end
  end

  it "#unknown? as error? when false" do
    use_config(default_level: :fatal) do
      expect(logger.unknown?).to eq(false)
    end
  end

  it "#silence_logger" do
    logger.silence_logger { logger.info("hello world") }
    wait_for { mock_logger.message }.to be_falsey
  end

  it "#<< as info" do
    (logger << "hello world")
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ I \[\d+:#{@thread_name}\] CompatibilityTest -- hello world/)
  end

  it "#progname= as #name=" do
    expect(logger.name).to eq("CompatibilityTest")
    logger.progname = "NewTest"
    expect(logger.name).to eq("NewTest")
  end

  it "#progname as #name" do
    expect(logger.name).to eq("CompatibilityTest")
    expect(logger.progname).to eq("CompatibilityTest")
  end

  it "#sev_threshold= as #level=" do
    expect(logger.level).to eq(:trace)
    logger.sev_threshold = Logger::DEBUG
    expect(logger.level).to eq(:debug)
  end

  it "#sev_threshold as #level" do
    expect(logger.level).to eq(:trace)
    expect(logger.sev_threshold).to eq(:trace)
  end

  it "#formatter NOOP" do
    expect(logger.formatter).to eq(nil)
    logger.formatter = "blah"
    expect(logger.formatter).to eq("blah")
  end

  it "#datetime_format NOOP" do
    expect(logger.datetime_format).to eq(nil)
    logger.datetime_format = "blah"
    expect(logger.datetime_format).to eq("blah")
  end

  it "#close NOOP" do
    logger.close
    logger.info("hello world") { "Data" }
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ I \[\d+:#{@thread_name}\] CompatibilityTest -- hello world -- Data/)
  end

  it "#reopen NOOP" do
    logger.reopen
    logger.info("hello world") { "Data" }
    wait_for { mock_logger.message }.to match(/\d+-\d+-\d+ \d+:\d+:\d+.\d+ I \[\d+:#{@thread_name}\] CompatibilityTest -- hello world -- Data/)
  end
end
# rubocop:enable LineLength
