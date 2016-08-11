require "spec_helper"
require "stringio"

class TestAttribute
  include Sapience::Loggable
end

module Perform
  def perform
    logger.info("perform")
  end
end

class Base
  include Sapience::Loggable
  include Perform
end

module Process
  def process
    logger.info("process")
  end
end

class Subclass < Base
  include Process
end

# rubocop:disable LineLength
describe Sapience::Loggable do
  describe "inheritance" do
    it "should give child classes their own logger" do
      expect(Subclass.logger.name).to eq(Subclass.name)
      expect(Base.logger.name).to eq(Base.name)
      expect(Subclass.logger.name).to eq(Subclass.name)
      child_logger = Subclass.logger
      expect(Base.logger).to_not eq(child_logger)
      expect(Subclass.logger.object_id).to eq(child_logger.object_id)
    end

    it "should give child objects their own logger" do
      subclass = Subclass.new
      base = Base.new
      expect(subclass.logger.name).to eq(subclass.class.name)
      expect(base.logger.name).to eq(base.class.name)
      expect(subclass.logger.name).to eq(subclass.class.name)
      child_logger = subclass.logger
      expect(base.logger).to_not eq(child_logger)
      expect(subclass.logger.object_id).to eq(child_logger.object_id)
    end

    it "should allow mixins to call parent logger" do
      base = Base.new
      expect(Base.logger).to receive(:info).with("perform")
      base.perform
    end

    it "should allow child mixins to call parent logger" do
      subclass = Subclass.new
      expect(Subclass.logger).to receive(:info).with("process")
      subclass.process
    end
  end

  describe "logger" do
    before do
      @time = Time.new
      @io = StringIO.new
      @appender = Sapience::Appender::File.new(@io)
      Sapience.config.default_level = :trace
      @mock_logger = MockLogger.new
      @appender = Sapience.add_appender(:wrapper, logger: (@mock_logger))
      @hash = { session_id: "HSSKLEU@JDK767", tracking_number: 12_345 }
      @hash_str = @hash.inspect.sub("{", "\\{").sub("}", "\\}")
      @thread_name = Thread.current.name
    end

    after { Sapience.remove_appender(@appender) }

    describe "for each log level" do
      Sapience::LEVELS.each do |level|
        it "log #{level} information with class attribute" do
          allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
          allow(Sapience).to receive(:appenders).and_return([@appender])
          TestAttribute.logger.send(level, "hello #{level}", @hash)
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} \w \[\d+:#{@thread_name} example.rb:\d+\] TestAttribute -- hello #{level} -- #{@hash_str}/)
        end

        it "log #{level} information with instance attribute" do
          allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
          allow(Sapience).to receive(:appenders).and_return([@appender])
          TestAttribute.new.logger.send(level, "hello #{level}", @hash)
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} \w \[\d+:#{@thread_name} example.rb:\d+\] TestAttribute -- hello #{level} -- #{@hash_str}/)
        end
      end
    end
  end
end
# rubocop:enable LineLength
