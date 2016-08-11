require "spec_helper"

# rubocop:disable LineLength
describe Sapience::Logger do

  [nil, /\ALogger/, ->(l) { (l.message =~ /\AExclude/).nil? }].each do |filter|
    describe "filter: #{filter.class.name}" do
      before do
        Sapience.config.default_level = :trace
        Sapience.config.backtrace_level = nil
        @mock_logger = MockLogger.new
        @appender = Sapience.add_appender(:wrapper, logger: (@mock_logger))
        @appender.filter = filter
        @logger = Sapience["LoggerTest"]
        @hash = { session_id: "HSSKLEU@JDK767", tracking_number: 12_345 }
        @hash_str = @hash.inspect.sub("{", "\\{").sub("}", "\\}")
        @thread_name = Thread.current.name
        @file_name_reg_exp = " example.rb:\\d+"
        expect(@logger.tags).to(eq([]))
        expect(Sapience.config.backtrace_level_index).to(eq(65_535))
      end

      after { Sapience.remove_appender(@appender) }

      Sapience::LEVELS.each do |level|
        level_char = level.to_s.upcase[0]
        describe level do
          it "logs" do
            @logger.send(level, "hello world", @hash) { "Calculations" }
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
          end

          it "exclude log messages using Proc filter" do
            if filter.is_a?(Proc)
              @logger.send(level, "Exclude this log message", @hash) { "Calculations" }
              Sapience.flush
              expect(@mock_logger.message).to(be_nil)
            end
          end

          it "exclude log messages using RegExp filter" do
            if filter.is_a?(Regexp)
              logger = Sapience::Logger.new("NotLogger", :trace, filter)
              logger.send(level, "Ignore all log messages from this class", @hash) do
                "Calculations"
              end

              Sapience.flush
              expect(@mock_logger.message).to(be_nil)
            end
          end

          it "logs with backtrace" do
            allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
            @logger.send(level, "hello world", @hash) { "Calculations" }
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
          end

          it "logs with backtrace and exception" do
            allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
            exc = RuntimeError.new("Test")
            @logger.send(level, "hello world", exc)
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] LoggerTest -- hello world -- Exception: RuntimeError: Test/)
          end

          it "logs payload" do
            hash = { tracking_number: "123456", even: 2, more: "data" }
            hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
            @logger.send(level, "Hello world", hash)
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
          end

          it "does not log an empty payload" do
            hash = {}
            @logger.send(level, "Hello world", hash)
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world/)
          end

          describe "hash only argument" do
            it "logs message" do
              @logger.send(level, message: "Hello world")
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world/)
            end

            it "logs payload and message" do
              @logger.send(level, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              Sapience.flush
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "logs payload and message from block" do
              @logger.send(level) do
                { message: "Hello world", tracking_number: "123456", even: 2, more: "data" }
              end

              hash = { tracking_number: "123456", even: 2, more: "data" }
              Sapience.flush
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "logs payload only" do
              hash = { tracking_number: "123456", even: 2, more: "data" }
              @logger.send(level, hash)
              Sapience.flush
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] LoggerTest -- #{hash_str}/)
            end

            it "logs duration" do
              @logger.send(level, duration: 123.45, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              Sapience.flush
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              duration_match = "\\(123\\.5ms\\)"
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] #{duration_match} LoggerTest -- Hello world -- #{hash_str}/)
            end

            it "does not log when below min_duration" do
              @logger.send(level, min_duration: 200, duration: 123.45, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              Sapience.flush
              expect(@mock_logger.message).to(be_nil)
            end

            it "logs duration" do
              metric_name = "/my/custom/metric"
              @logger.send(level, metric: metric_name, duration: 123.45, message: "Hello world", tracking_number: "123456", even: 2, more: "data")
              hash = { tracking_number: "123456", even: 2, more: "data" }
              Sapience.flush
              hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
              duration_match = "\\(123\\.5ms\\)"
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] #{duration_match} LoggerTest -- Hello world -- #{hash_str}/)
            end
          end
        end
      end

      describe "#tagged" do
        it "add tags to log entries" do
          @logger.tagged("12345", "DJHSFK") do
            @logger.info("Hello world")
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[12345\] \[DJHSFK\] LoggerTest -- Hello world/)
          end
        end

        it "add embedded tags to log entries" do
          @logger.tagged("First Level", "tags") do
            @logger.tagged("Second Level") do
              @logger.info("Hello world")
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[First Level\] \[tags\] \[Second Level\] LoggerTest -- Hello world/)
            end

            expect(@logger.tags.count).to(eq(2))
            expect(@logger.tags.first).to(eq("First Level"))
            expect(@logger.tags.last).to(eq("tags"))
          end
        end
      end

      describe "#with_payload" do
        it "logs tagged payload" do
          hash = { tracking_number: "123456", even: 2, more: "data" }
          hash_str = hash.inspect.sub("{", "\\{").sub("}", "\\}")
          @logger.with_payload(tracking_number: "123456") do
            @logger.with_payload(even: 2, more: "data") do
              @logger.info("Hello world")
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] LoggerTest -- Hello world -- #{hash_str}/)
            end
          end
        end
      end

      describe "#fast_tag" do
        it "add string tag to log entries" do
          @logger.fast_tag("12345") do
            @logger.info("Hello world")
            Sapience.flush
            expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \[12345\] LoggerTest -- Hello world/)
          end
        end
      end

      describe "Ruby Logger level" do
        Logger::Severity.constants.each do |level|
          it "log Ruby logger #{level} info" do
            @logger.level = Logger::Severity.const_get(level)
            if (level.to_s == "UNKNOWN")
              expect(@logger.send(:level_index)).to(eq((Logger::Severity.const_get("ERROR") + 1)))
            else
              expect(@logger.send(:level_index)).to(eq((Logger::Severity.const_get(level) + 1)))
            end
          end
        end
      end

      describe "measure" do
        Sapience::LEVELS.each do |level|
          level_char = level.to_s.upcase[0]
          describe "direct method" do
            it "log #{level} info" do
              expect(@logger.send("measure_#{level}".to_sym, "hello world") { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end

            it "log #{level} info with payload" do
              expect(@logger.send("measure_#{level}".to_sym, "hello world", payload: (@hash)) do
                "result"
              end,
              ).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "not log #{level} info when block is faster than :min_duration" do
              expect(@logger.send("measure_#{level}".to_sym, "hello world", min_duration: 500) do
                "result"
              end,
              ).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to(be_nil)
            end

            it "log #{level} info when block duration exceeds :min_duration" do
              expect(@logger.send("measure_#{level}".to_sym, "hello world", min_duration: 200, payload: (@hash)) do
                sleep(0.5)
                "result"
              end,
              ).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "log #{level} info with an exception" do
              expect do ||
                @logger.send("measure_#{level}", "hello world", payload: (@hash)) do
                  fail("Test")
                end
              end
                .to(raise_error(RuntimeError))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "change log #{level} info with an exception" do
              expect do
                @logger.send("measure_#{level}", "hello world", payload: (@hash), on_exception_level: :fatal) do
                  fail("Test")
                end
              end.to(raise_error(RuntimeError))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} F \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "log #{level} info with backtrace" do
              allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
              expect(@logger.send("measure_#{level}".to_sym, "hello world") { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end
          end

          describe "generic method" do
            it "log #{level} info" do
              expect(@logger.measure(level, "hello world") { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end

            it "log #{level} info with payload" do
              expect(@logger.measure(level, "hello world", payload: (@hash)) { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "not log #{level} info when block is faster than :min_duration" do
              expect(@logger.measure(level, "hello world", min_duration: 500) { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to(be_nil)
            end

            it "log #{level} info when block duration exceeds :min_duration" do
              expect(@logger.measure(level, "hello world", min_duration: 200, payload: (@hash)) do
                sleep(0.5)
                "result"
              end,
              ).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
            end

            it "log #{level} info with an exception" do
              expect do ||
                @logger.measure(level, "hello world", payload: (@hash)) do
                  fail("Test")
                end
              end
                .to(raise_error(RuntimeError))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- Exception: RuntimeError: Test -- #{@hash_str}/)
            end

            it "log #{level} info with backtrace" do
              allow(Sapience.config).to receive(:backtrace_level_index).and_return(0)
              expect(@logger.measure(level, "hello world") { "result" }).to(eq("result"))
              Sapience.flush
              expect(@mock_logger.message).to match(/#{TS_REGEX} #{level_char} \[\d+:#{@thread_name}#{@file_name_reg_exp}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
            end
          end
        end

        it "log when the block performs a return" do
          expect(function_with_return(@logger)).to(eq("Good"))
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world -- #{@hash_str}/)
        end

        it "not log at a level below the silence level" do
          Sapience.config.default_level = :info
          @logger.measure_info("hello world", silence: :error) do
            @logger.warn("don't log me")
          end

          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
        end

        it "log at a silence level below the default level" do
          Sapience.config.default_level = :info
          first_message = nil
          @logger.measure_info("hello world", silence: :trace) do
            @logger.debug("hello world", @hash) { "Calculations" }
            Sapience.flush
            first_message = @mock_logger.message
          end

          expect(first_message).to match(/#{TS_REGEX} D \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} I \[\d+:#{@thread_name}\] \((\d+\.\d+)|(\d+)ms\) LoggerTest -- hello world/)
        end
      end

      describe ".default_level" do
        before { Sapience.config.default_level = :debug }
        it "not log at a level below the global default" do
          expect(Sapience.config.default_level).to(eq(:debug))
          expect(@logger.level).to(eq(:debug))
          @logger.trace("hello world", @hash) { "Calculations" }
          Sapience.flush
          expect(@mock_logger.message).to(be_nil)
        end

        it "log at the instance level" do
          expect(Sapience.config.default_level).to(eq(:debug))
          @logger.level = :trace
          expect(@logger.level).to(eq(:trace))
          @logger.trace("hello world", @hash) { "Calculations" }
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} T \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end

        it "not log at a level below the instance level" do
          expect(Sapience.config.default_level).to(eq(:debug))
          @logger.level = :warn
          expect(@logger.level).to(eq(:warn))
          @logger.debug("hello world", @hash) { "Calculations" }
          Sapience.flush
          expect(@mock_logger.message).to(be_nil)
        end
      end

      describe ".silence" do
        before { Sapience.config.default_level = :info }
        it "not log at a level below the silence level" do
          expect(Sapience.config.default_level).to(eq(:info))
          expect(@logger.level).to(eq(:info))
          @logger.silence do
            @logger.warn("hello world", @hash) { "Calculations" }
            @logger.info("hello world", @hash) { "Calculations" }
            @logger.debug("hello world", @hash) { "Calculations" }
            @logger.trace("hello world", @hash) { "Calculations" }
          end

          Sapience.flush
          expect(@mock_logger.message).to(be_nil)
        end

        it "log at the instance level even with the silencer at a higher level" do
          @logger.level = :trace
          expect(@logger.level).to(eq(:trace))
          @logger.silence { @logger.trace("hello world", @hash) { "Calculations" } }
          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} T \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end

        it "log at a silence level below the default level" do
          expect(Sapience.config.default_level).to(eq(:info))
          expect(@logger.level).to(eq(:info))
          @logger.silence(:debug) do
            @logger.debug("hello world", @hash) { "Calculations" }
          end

          Sapience.flush
          expect(@mock_logger.message).to match(/#{TS_REGEX} D \[\d+:#{@thread_name}\] LoggerTest -- hello world -- Calculations -- #{@hash_str}/)
        end
      end

      describe ".level?" do
        it "return true for debug? with :trace level" do
          Sapience.config.default_level = :trace
          expect(@logger.level).to(eq(:trace))
          expect(@logger.debug?).to(eq(true))
          expect(@logger.trace?).to(eq(true))
        end

        it "return false for debug? with global :debug level" do
          Sapience.config.default_level = :debug
          expect(@logger.level).to(eq(:debug))
          expect(@logger.debug?).to(eq(true))
          expect(@logger.trace?).to(eq(false))
        end

        it "return true for debug? with global :info level" do
          Sapience.config.default_level = :info
          expect(@logger.level).to(eq(:info))
          expect(@logger.debug?).to(eq(false))
          expect(@logger.trace?).to(eq(false))
        end

        it "return false for debug? with instance :debug level" do
          @logger.level = :debug
          expect(@logger.level).to(eq(:debug))
          expect(@logger.debug?).to(eq(true))
          expect(@logger.trace?).to(eq(false))
        end

        it "return true for debug? with instance :info level" do
          @logger.level = :info
          expect(@logger.level).to(eq(:info))
          expect(@logger.debug?).to(eq(false))
          expect(@logger.trace?).to(eq(false))
        end
      end
    end
  end

  def function_with_return(logger)
    logger.measure_info("hello world", payload: (@hash)) { return "Good" }
    "Bad"
  end
end
# rubocop:enable LineLength
