# frozen_string_literal: true
require "spec_helper"

# rubocop:disable LineLength
describe Sapience::Logger do
  let(:mock_logger) { MockLogger.new }
  let(:appender) { Sapience.add_appender(:wrapper, logger: mock_logger) }
  let(:logger) { Sapience["LoggerTest"] }

  describe ".logger" do
    context "when @logger is nil" do
      before do
        described_class.class_variable_set(:@@logger, nil)
      end

      specify do
        expect(described_class.logger).to be_a(Sapience::Logger)
      end
    end
  end

  describe ".flush" do
    it "flushes, closes and removes appender" do
      expect(described_class.logger).to receive(:trace).with("Appender thread: Flushing appender: #{appender.class.name}")
      expect(described_class.logger).to receive(:trace).with("Appender thread: All appenders flushed")
      expect(appender).to receive(:flush).and_call_original
      described_class.flush
    end

    context "when appender.flush raises StandardError" do
      let(:exception) { StandardError.new("Flush failed") }
      it "logs an additional message about the error" do
        expect(described_class.logger)
          .to receive(:trace)
          .with("Appender thread: Flushing appender: #{appender.class.name}")

        expect(described_class.logger)
          .to receive(:trace)
          .with("Appender thread: All appenders flushed")

        expect($stderr)
          .to receive(:write)
          .with("Appender thread: Failed to flush to appender: #{appender.inspect}\n #{exception.inspect}")

        expect(appender).to receive(:flush).and_raise(exception)
        expect { described_class.flush }.not_to raise_error
      end
    end

    context "when appender.flush raises Exception" do
      let(:exception) { Exception.new("Flush failed") }
      it "logs an additional message about the error" do
        expect(described_class.logger)
          .to receive(:trace)
          .with("Appender thread: Flushing appender: #{appender.class.name}")

        expect(described_class.logger)
          .not_to receive(:trace)
          .with("Appender thread: All appenders flushed")

        expect(described_class.logger)
          .not_to receive(:error)

        expect(appender).to receive(:flush).and_raise(exception)
        expect { described_class.flush }.to raise_error(Exception, "Flush failed")
      end
    end
  end

  describe ".close" do
    it "flushes, closes and removes appender" do
      expect(described_class.logger).to receive(:trace).with("Appender thread: Closing appender: #{appender.name}")
      expect(described_class.logger).to receive(:trace).with("Appender thread: All appenders flushed")
      expect(appender).to receive(:flush).and_call_original
      expect(appender).to receive(:close).and_call_original
      expect(Sapience).to receive(:remove_appender).with(appender)
      described_class.close
    end

    context "when appender.flush raises StandardError" do
      let(:exception) { StandardError.new("Flush failed") }
      it "logs an additional message about the error" do
        expect(described_class.logger).to receive(:trace).with("Appender thread: Closing appender: #{appender.name}")
        expect(described_class.logger).to receive(:trace).with("Appender thread: All appenders flushed")
        expect(appender).to receive(:flush).and_raise(exception)
        expect(appender).not_to receive(:close)
        expect(Sapience).not_to receive(:remove_appender)

        expect { described_class.close }.not_to raise_error
      end
    end

    context "when appender.flush raises Exception" do
      let(:exception) { Exception.new("Flush failed") }
      it "logs an additional message about the error" do
        expect(described_class.logger).to receive(:trace).with("Appender thread: Closing appender: #{appender.name}")
        expect(described_class.logger).not_to receive(:trace).with("Appender thread: All appenders flushed")
        expect(appender).to receive(:flush).and_raise(exception)
        expect(appender).not_to receive(:close)
        expect(Sapience).not_to receive(:remove_appender)

        expect { described_class.close }.to raise_error(Exception, "Flush failed")
      end
    end
  end

  describe ".close_appender" do
    it "flushes, closes and removes appender" do
      expect(described_class.logger).to receive(:trace).with("Appender thread: Closing appender: #{appender.name}")
      expect(appender).to receive(:flush).and_call_original
      expect(appender).to receive(:close).and_call_original
      expect(Sapience).to receive(:remove_appender).with(appender)
      described_class.close_appender(appender)
    end
  end

  describe "#log" do
    include_context "logs"
    let(:appender) { Sapience.add_appender(:stream, file_name: "log/test.log", formatter: :color) }
    let(:ex) { StandardError.new("We failed") }
    subject(:logger) { described_class.new("Test", :info) }

    specify "handles standard error" do
      allow(described_class).to receive(:logger).and_return(appender)
      allow(appender).to receive(:log).with(log).and_raise(ex)

      expect($stderr).to receive(:write).with("Appender thread: Failed to log to appender: #{appender.inspect}\n #{ex.inspect}")
      subject.log(log, "whaatever", "sapience")
    end

    specify "raises exceptions" do
      allow(described_class).to receive(:logger).and_return(appender)
      allow(appender).to receive(:log).with(log).and_raise(Exception, "We failed")
      expect(appender).not_to receive(:error)
      expect { subject.log(log, "whaatever", "sapience") }
        .to raise_error(Exception, "We failed")
    end
  end

  [nil, /\ALogger/, ->(l) { (l.message =~ /\AExclude/).nil? }].each do |filter| # rubocop:disable Performance/StartWith
    describe "filter: #{filter.class.name}" do
      force_config(default_level: :trace, backtrace_level: nil)
      before do
        appender.filter = filter
        @hash = { session_id: "HSSKLEU@JDK767", tracking_number: 12_345 }
        @hash_str = @hash.inspect.sub("{", "\\{").sub("}", "\\}")
        @thread_name = Thread.current.name
        @file_name_reg_exp = " example.rb:\\d+"
        expect(logger.tags).to(eq([]))
        expect(Sapience.config.backtrace_level_index).to(eq(65_535))
      end

      after do
        Sapience.remove_appenders
      end

      Sapience::LEVELS.each do |level|
        level_char = level.to_s.upcase[0]
        describe level do
          it "logs" do
            logger.send(level, "hello world", @hash) { "Calculations" }
            expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
          end

          it "exclude log messages using Proc filter" do
            if filter.is_a?(Proc)
              logger.send(level, "Exclude this log message", @hash) { "Calculations" }
              expect(mock_logger.message).to(be_nil)
            end
          end

          it "exclude log messages using RegExp filter" do
            if filter.is_a?(Regexp)
              logger = Sapience::Logger.new("NotLogger", :trace, filter)
              logger.send(level, "Ignore all log messages from this class", @hash) do
                "Calculations"
              end

              expect(mock_logger.message).to(be_nil)
            end
          end

          it "logs with backtrace" do
            allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
            logger.send(level, "hello world", @hash) { "Calculations" }
            expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
          end

          it "logs with backtrace and exception" do
            allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
            exc = RuntimeError.new("Test")
            logger.send(level, "hello world", exc)
            expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] LoggerTest -- hello world -- Exception: RuntimeError: Test/)
          end

          it "logs payload" do
            hash = { tracking_number: "123456", even: 2, more: "data" }
            hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
            logger.send(level, "Hello world", hash)
            expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
          end

          it "does not log an empty payload" do
            hash = {}
            logger.send(level, "Hello world", hash)
            expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world/)
          end

          describe "hash only argument" do
            it "logs message" do
              logger.send(level, message: "Hello world")
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world/)
            end

            it "logs payload and message" do
              logger.send(level, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "logs payload and message from block" do
              logger.send(level, message: "Hello world", tracking_number: "123456", even: 2, more: "data")

              hash = { tracking_number: "123456", even: 2, more: "data" }
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "logs payload only" do
              hash = { tracking_number: "123456", even: 2, more: "data" }
              logger.send(level, hash)
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- #{hash_str}/)
            end

            it "logs duration" do
              logger.send(level, duration: 123.4, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              duration_match = "\\(123\\.4ms\\)"
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] #{duration_match} LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "does not log when below min_duration" do
              logger.send(level, min_duration: 200, duration: 123.4, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              expect(mock_logger.message).to(be_nil)
            end

            it "logs duration" do
              metric_name = "/my/custom/metric"
              logger.send(level, metric: metric_name, duration: 123.4, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              duration_match = "\\(123\\.4ms\\)"
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] #{duration_match} LoggerTest -- Hello world -- #{hash_str}/)
            end
          end
        end
      end

      describe "log hooks" do
        let(:extra_payload) { { foo: :bar } }
        let(:overridden_message) { "hey, ho, let's go!" }

        class APMTracer
          def self.trace_data
            {
              dd: {
                trace_id: "XXX",
                span_id: "YYY",
              },
            }
          end
        end

        before do
          logger.log_hooks << lambda do |log|
            log.message = overridden_message
          end

          logger.log_hooks << lambda do |log|
            log.payload? ? log.payload.merge!(extra_payload) : log.payload = extra_payload
          end

          logger.log_hooks << lambda do |log|
            trace_data = APMTracer.trace_data
            log.payload? ? log.payload.merge!(trace_data) : log.payload = trace_data
          end
        end

        it "'log hooks' change the Log object" do
          logger.info(message: "Hello world", tracking_number: "123456", even: 2, more: "data")
          hash = { tracking_number: "123456", even: 2, more: "data" }
          hash_str = hash.merge(extra_payload).merge(APMTracer.trace_data).inspect.sub("{", "\\{").sub("}", "\\}")

          expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] LoggerTest -- #{overridden_message} -- #{hash_str}/)
        end
      end

      describe "#tagged" do
        it "add tags to log entries" do
          logger.tagged("12345", "DJHSFK") do
            logger.info("Hello world")
            expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[12345\] \[DJHSFK\] LoggerTest -- Hello world/)
          end
        end

        it "add embedded tags to log entries" do
          logger.tagged("First Level", "tags") do
            logger.tagged("Second Level") do
              logger.info("Hello world")
              expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[First Level\] \[tags\] \[Second Level\] LoggerTest -- Hello world/)
            end
          end
        end
      end

      describe "#with_payload" do
        it "logs tagged payload" do
          hash = { tracking_number: "123456", even: 2, more: "data" }
          hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
          logger.with_payload(tracking_number: "123456") do
            logger.with_payload(even: 2, more: "data") do
              logger.info("Hello world")
              expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end
          end
        end
      end

      describe "#fast_tag" do
        it "add string tag to log entries" do
          logger.fast_tag("12345") do
            logger.info("Hello world")
            expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[12345\] LoggerTest -- Hello world/)
          end
        end
      end

      describe "Ruby Logger level" do
        Logger::Severity.constants.each do |level|
          it "log Ruby logger #{level} info" do
            logger.level = Logger::Severity.const_get(level)
            if level.to_s == "UNKNOWN"
              expect(logger.send(:level_index)).to(eq((Logger::Severity.const_get("ERROR") + 1)))
            else
              expect(logger.send(:level_index)).to(eq((Logger::Severity.const_get(level) + 1)))
            end
          end
        end
      end

      describe "measure" do
        Sapience::LEVELS.each do |level|
          level_char = level.to_s.upcase[0]
          describe "direct method" do
            it "log #{level} info" do
              expect(logger.send("measure_#{level}".to_sym, "hello world") { "result" }).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end

            it "log #{level} info with payload" do
              expect(logger.send("measure_#{level}".to_sym, "hello world", payload: @hash) do
                "result"
              end).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "not log #{level} info when block is faster than :min_duration" do
              expect(logger.send("measure_#{level}".to_sym, "hello world", min_duration: 500) do
                "result"
              end).to(eq("result"))
              expect(mock_logger.message).to(be_nil)
            end

            it "log #{level} info when block duration exceeds :min_duration" do
              expect(logger.send("measure_#{level}".to_sym, "hello world", min_duration: 200, payload: @hash) do
                sleep(0.5)
                "result"
              end).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "log #{level} info with an exception" do
              expect do
                logger.send("measure_#{level}", "hello world", payload: @hash) do
                  fail("Test")
                end
              end
                .to(raise_error(RuntimeError))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "change log #{level} info with an exception" do
              expect do
                logger.send("measure_#{level}", "hello world", payload: @hash, on_exception_level: :fatal) do
                  fail("Test")
                end
              end.to(raise_error(RuntimeError))
              expect(mock_logger.message).to match(/#{TS_REGEX} F \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "log #{level} info with backtrace" do
              allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
              expect(logger.send("measure_#{level}".to_sym, "hello world") { "result" }).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end
          end

          describe "generic method" do
            it "log #{level} info" do
              expect(logger.measure(level, "hello world") { "result" }).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end

            it "log #{level} info with payload" do
              expect(logger.measure(level, "hello world", payload: @hash) { "result" }).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "not log #{level} info when block is faster than :min_duration" do
              expect(logger.measure(level, "hello world", min_duration: 500) { "result" }).to(eq("result"))
              expect(mock_logger.message).to(be_nil)
            end

            it "log #{level} info when block duration exceeds :min_duration" do
              expect(logger.measure(level, "hello world", min_duration: 200, payload: @hash) do
                sleep(0.5)
                "result"
              end).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "log #{level} info with an exception" do
              expect do
                logger.measure(level, "hello world", payload: @hash) do
                  fail("Test")
                end
              end
                .to(raise_error(RuntimeError))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "log #{level} info with backtrace" do
              allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
              expect(logger.measure(level, "hello world") { "result" }).to(eq("result"))
              expect(mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end
          end
        end

        it "log when the block performs a return" do
          expect(function_with_return(logger)).to(eq("Good"))
          expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
        end

        it "not log at a level below the silence level" do
          use_config(default_level: :info) do
            logger.measure_info("hello world", silence: :error) do
              logger.warn("don't log me")
            end

            expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
          end
        end

        it "log at a silence level below the default level" do
          use_config(default_level: :info) do
            logger.measure_info("hello world", silence: :trace) do
              logger.debug("hello world", @hash) { "Calculations" }
              expect(mock_logger.message).to match(/#{TS_REGEX} D \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
            end

            expect(mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
          end
        end
      end

      describe ".default_level" do
        force_config(default_level: :debug)
        it "not log at a level below the global default" do
          expect(Sapience.config.default_level).to(eq(:debug))
          expect(logger.level).to(eq(:debug))
          logger.trace("hello world", @hash) { "Calculations" }
          expect(mock_logger.message).to(be_nil)
        end

        it "log at the instance level" do
          expect(Sapience.config.default_level).to(eq(:debug))
          logger.level = :trace
          expect(logger.level).to(eq(:trace))
          logger.trace("hello world", @hash) { "Calculations" }
          expect(mock_logger.message).to match(/#{TS_REGEX} T \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end

        it "not log at a level below the instance level" do
          expect(Sapience.config.default_level).to(eq(:debug))
          logger.level = :warn
          expect(logger.level).to(eq(:warn))
          logger.debug("hello world", @hash) { "Calculations" }
          expect(mock_logger.message).to(be_nil)
        end
      end

      describe ".silence" do
        force_config(default_level: :info)
        it "not log at a level below the silence level" do
          expect(Sapience.config.default_level).to(eq(:info))
          expect(logger.level).to(eq(:info))
          logger.silence do
            logger.warn("hello world", @hash) { "Calculations" }
            logger.info("hello world", @hash) { "Calculations" }
            logger.debug("hello world", @hash) { "Calculations" }
            logger.trace("hello world", @hash) { "Calculations" }
          end

          expect(mock_logger.message).to(be_nil)
        end

        it "log at the instance level even with the silencer at a higher level" do
          logger.level = :trace
          expect(logger.level).to(eq(:trace))
          logger.silence { logger.trace("hello world", @hash) { "Calculations" } }
          expect(mock_logger.message).to match(/#{TS_REGEX} T \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end

        it "log at a silence level below the default level" do
          expect(Sapience.config.default_level).to(eq(:info))
          expect(logger.level).to(eq(:info))
          logger.silence(:debug) do
            logger.debug("hello world", @hash) { "Calculations" }
          end

          expect(mock_logger.message).to match(/#{TS_REGEX} D \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end
      end

      describe ".level?" do
        it "return true for debug? with :trace level" do
          use_config(default_level: :trace) do
            expect(logger.level).to(eq(:trace))
            expect(logger.debug?).to(eq(true))
            expect(logger.trace?).to(eq(true))
          end
        end

        it "return false for debug? with global :debug level" do
          use_config(default_level: :debug) do
            expect(logger.level).to(eq(:debug))
            expect(logger.debug?).to(eq(true))
            expect(logger.trace?).to(eq(false))
          end
        end

        it "return true for debug? with global :info level" do
          use_config(default_level: :info) do
            expect(logger.level).to(eq(:info))
            expect(logger.debug?).to(eq(false))
            expect(logger.trace?).to(eq(false))
          end
        end

        it "return false for debug? with instance :debug level" do
          logger.level = :debug
          expect(logger.level).to(eq(:debug))
          expect(logger.debug?).to(eq(true))
          expect(logger.trace?).to(eq(false))
        end

        it "return true for debug? with instance :info level" do
          logger.level = :info
          expect(logger.level).to(eq(:info))
          expect(logger.debug?).to(eq(false))
          expect(logger.trace?).to(eq(false))
        end
      end
    end
  end

  def function_with_return(logger)
    logger.measure_info("hello world", payload: @hash) { return "Good" }
    "Bad"
  end
end
# rubocop:enable LineLength
