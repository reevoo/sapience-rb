require "spec_helper"
describe Sapience::Appender::Wrapper do
  before do
    @time = Time.new
    @mock_logger = MockLogger.new
    @appender = Sapience::Appender::Wrapper.new(@mock_logger)
    @hash = { session_id: "HSSKLEU@JDK767", tracking_number: 12_345 }
    @hash_str = @hash.inspect.sub("{", "\\{").sub("}", "\\}")
  end

  describe "format logs into text form" do
    it "handle nil name, message and payload" do
      log = Sapience::Log.new
      log.time = Time.now
      log.level = :debug
      @appender.log(log)
      expect(@mock_logger.message).to match(/#{TS_REGEX} D \[\d+:\] /)
    end

    it "handle nil message and payload" do
      log = Sapience::Log.new
      log.time = Time.now
      log.level = :debug
      log.name = "class"
      @appender.log(log)
      expect(@mock_logger.message).to match(/#{TS_REGEX} D \[\d+:\] class/)
    end

    it "handle nil payload" do
      log = Sapience::Log.new
      log.time = Time.now
      log.level = :debug
      log.name = "class"
      log.message = "hello world"
      @appender.log(log)
      expect(@mock_logger.message).to match(/#{TS_REGEX} D \[\d+:\] class -- hello world/)
    end

    it "handle payload" do
      log = Sapience::Log.new
      log.time = Time.now
      log.level = :debug
      log.name = "class"
      log.message = "hello world"
      log.payload = @hash
      @appender.log(log)
      expect(@mock_logger.message).to match(/#{TS_REGEX} D \[\d+:\] class -- hello world -- #{@hash_str}/)
    end
  end

  describe "for each log level" do
    Logger::Severity.constants.each do |level|
      it "log #{level.downcase.to_sym} info" do
        @appender.log(Sapience::Log.new(level.downcase.to_sym, "thread", "class", "hello world", @hash, Time.now))
        expect(@mock_logger.message).to match(/#{TS_REGEX} \w \[\d+:thread\] class -- hello world -- #{@hash_str}/)
      end
    end
  end
end
