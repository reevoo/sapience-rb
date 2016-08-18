require "spec_helper"
require "stringio"

# rubocop:disable LineLength
describe Sapience::Appender::File do
  before do
    # TODO: Make sure we have always started an appender thread (Sapience::Logger.start_appender_thread)
    # Sapience::Logger.start_appender_thread
    Sapience.config.default_level = :trace
    @time                        = Time.new
    @io                          = StringIO.new
    @appender                    = Sapience.add_appender(:file, io: @io)
    @hash                        = { session_id: "HSSKLEU@JDK767", tracking_number: 12_345 }
    @hash_str                    = @hash.inspect.sub("{", "\\{").sub("}", "\\}")
    @thread_name                 = Thread.current.name
    @file_name_reg_exp           = " example.rb:\\d+"
  end

  describe "format logs into text form" do
    it "handle no message or payload" do
      @appender.debug
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File\n/)
    end

    it "handle message" do
      @appender.debug("hello world")
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- hello world\n/)
    end

    it "handle message and payload" do
      @appender.debug("hello world", @hash)
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- hello world -- #{@hash_str}\n/)
    end

    it "handle message, payload, and exception" do
      @appender.debug("hello world", @hash, StandardError.new("StandardError"))
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- hello world -- #{@hash_str} -- Exception: StandardError: StandardError\n\n/)
    end

    it "logs exception with nil backtrace" do
      @appender.debug(StandardError.new("StandardError"))
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- Exception: StandardError: StandardError\n\n/)
    end

    it "handle nested exception" do
      begin
        fail(StandardError, "FirstError")
      rescue Exception # rubocop:disable RescueException
        begin
          fail(StandardError, "SecondError")
        rescue Exception => e2 # rubocop:disable RescueException
          @appender.debug(e2)
        end
      end
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- Exception: StandardError: SecondError\n/)

      if Exception.instance_methods.include?(:cause)
        expect(@io.string).to match(/^Cause: StandardError: FirstError\n/)
      end
    end

    it "logs exception with empty backtrace" do
      exc = StandardError.new("StandardError")
      exc.set_backtrace([])
      @appender.debug(exc)
      expect(@io.string).to match(/#{TS_REGEX} D \[\d+:#{@thread_name} example.rb:\d+\] Sapience::Appender::File -- Exception: StandardError: StandardError\n\n/)
    end
  end

  describe "for each log level" do
    Sapience::LEVELS.each do |level|
      it "log #{level} with file_name" do
        allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
        @appender.send(level, "hello world", @hash)
        expect(@io.string).to match(/#{TS_REGEX} \w \[\d+:#{@thread_name}#{@file_name_reg_exp}\] Sapience::Appender::File -- hello world -- #{@hash_str}\n/)
      end

      it "log #{level} without file_name" do
        allow(Sapience.config).to receive(:backtrace_level_index).and_return(100)
        @appender.send(level, "hello world", @hash)
        expect(@io.string).to match(/#{TS_REGEX} \w \[\d+:#{@thread_name}\] Sapience::Appender::File -- hello world -- #{@hash_str}\n/)
      end
    end
  end

  describe "custom formatter" do
    before do
      @appender = Sapience::Appender::File.new(io: @io) do |log|
        if log.tags and (log.tags.size > 0)
          tags = (log.tags.collect { |tag| "[#{tag}]" }.join(" ") + " ")
        end
        message = log.message.to_s
        ((message << " -- ") << log.payload.inspect) if log.payload

        if log.exception
          ((message << " -- ") << "#{log.exception.class}: #{log.exception.message}\n#{(log.exception.backtrace or []).join("\n")}")
        end
        duration_str = "" unless log.duration
        duration_str ||= format(" (%.1fms)", log.duration)
        "#{log.formatted_time} #{log.level.to_s.upcase} [#{$PROCESS_ID}:#{log.thread_name}] #{tags}#{log.name} -- #{message}#{duration_str}"
      end
    end

    it "format using formatter" do
      @appender.debug
      expect(@io.string).to match(/#{TS_REGEX} DEBUG \[\d+:#{@thread_name}\] Sapience::Appender::File -- \n/)
    end
  end
end
# rubocop:enable LineLength
