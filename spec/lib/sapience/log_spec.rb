# frozen_string_literal: true
require "spec_helper"
require "active_record"

describe Sapience::Log do
  include_context "logs"

  subject { log }

  before do
    Sapience.configure
  end

  describe "#duration_to_s" do
    its(:duration_to_s) do
      is_expected.to eq("#{duration}.0ms")
    end

    context "when duration is nil" do
      let(:duration) { nil }
      its(:duration_to_s) do
        is_expected.to eq(nil)
      end
    end

    context "when duration is less than 10" do
      let(:duration) { 9 }
      its(:duration_to_s) do
        is_expected.to eq("#{duration}.000ms")
      end
    end
  end

  describe "#duration_human" do
    context "when duration equals a day" do
      let(:duration) { Sapience::MILLISECONDS_IN_DAY }
      its(:duration_human) do
        is_expected.to eq("1d")
      end
    end

    context "when duration equals two days" do
      let(:duration) { Sapience::MILLISECONDS_IN_DAY * 2 }
      its(:duration_human) do
        is_expected.to eq("2d")
      end
    end

    context "when duration is greater than one day" do
      let(:duration) do
        Sapience::MILLISECONDS_IN_DAY +
          Sapience::MILLISECONDS_IN_MINUTE * 15
      end
      its(:duration_human) do
        is_expected.to eq("1d 15m")
      end
    end

    context "when duration is greater than a minute" do
      let(:duration) { Sapience::MILLISECONDS_IN_MINUTE + 1 }

      its(:duration_human) do
        is_expected.to eq("1m 1ms")
      end
    end

    context "when duration equals a minute" do
      let(:duration) { Sapience::MILLISECONDS_IN_MINUTE }

      its(:duration_human) do
        is_expected.to eq("1m")
      end
    end

    context "when duration is less than a minute" do
      let(:duration) { Sapience::MILLISECONDS_IN_SECOND + 35 }

      its(:duration_human) do
        is_expected.to eq("1.035s")
      end
    end

    context "when duration is less than a second" do
      let(:duration) { 900 }

      its(:duration_human) do
        is_expected.to eq("900.0ms")
      end
    end

    context "when duration is less than 10 ms" do
      let(:duration) { 8 }

      its(:duration_human) do
        is_expected.to eq("8.000ms")
      end
    end

    context "when duration is nil" do
      let(:duration) { nil }
      its(:duration_human) do
        is_expected.to eq(nil)
      end
    end
  end

  describe "#level_to_s" do
    its(:level_to_s) do
      is_expected.to eq("I")
    end
  end

  # This is covering both the below methods:
  #   - #extract_file_and_line
  #   - #file_name_and_line
  describe "#process_info" do
    its(:process_info, 30) do
      is_expected.to match(/(\d+):Custom Thread sapience.rb:(\d+)/)
    end
  end

  describe "#formatted_time" do
    before { travel_to Time.new(2004, 11, 24, 0o1, 0o4, 44) }
    after { travel_back }
    its(:formatted_time) do
      is_expected.to eq("2004-11-24 01:04:44.000000")
    end
  end

  describe "#cleansed_message" do
    let(:message) { "\033[32mThis message is Green\033[0m" }
    its(:cleansed_message) do
      is_expected.to eq("This message is Green")
    end
  end

  describe "#payload_to_s" do
    let(:inspected) { "Yummie" }
    let(:payload) { double(:payload, payload?: true, inspect: inspected) }
    its(:payload_to_s) do
      is_expected.to eq(inspected)
    end
  end

  describe "#payload?" do
    let(:payload) do
      {
        key: "value",
      }
    end
    context "when payload is nil" do
      let(:payload) { nil }
      its(:payload?) do
        is_expected.to eq(false)
      end
    end

    context "when payload is empty?" do
      let(:payload) { [] }
      its(:payload?) do
        is_expected.to eq(false)
      end
    end

    its(:payload?) do
      is_expected.to eq(true)
    end
  end

  describe "#to_h" do
    let(:shared_hash) do
      {
        app_name: "Sapience RSpec",
        duration: "9.999s",
        duration_ms: duration,
        exception: a_hash_including(
          name: exception.class.name,
          message: exception_message_two,
          stack_trace: a_kind_of(Array),
        ),
        file: a_string_ending_with("/sapience.rb"),
        host: a_kind_of(String),
        level: :info,
        level_index: 2,
        line: a_kind_of(Integer),
        message: message,
        metric: metric,
        name: name,
        pid: a_kind_of(Integer),
        tags: tags,
        thread: thread_name,
        time: a_kind_of(Time),
        environment: Sapience.environment,
      }
    end

    context "when payload is nil" do
      let(:expected) { shared_hash }

      its(:to_h) do
        is_expected.to match(expected)
      end
    end

    context "when payload is a Hash" do
      let(:expected) do
        shared_hash.merge(payload)
      end
      let(:payload) do
        { hey: "ho" }
      end

      its(:to_h) do
        is_expected.to match(expected)
      end

      context "when payload contains sensitive information" do
        let(:payload) do
          {
            params: {
              "password" => "some_password",
              "password_confirmation" => "some_password",
              "foo" => "bar",
            },
          }
        end

        it "replaces the value of default fields to [FILTERED]" do
          expect(subject.to_h[:params]).to eq(
            "password" => "[FILTERED]",
            "password_confirmation" => "[FILTERED]",
            "foo" => "bar",
          )
        end

        context "with configuration" do
          describe "overriding configuration" do
            before(:each) do
              allow(Sapience.config).to receive(:filter_parameters).and_return(["foo"])
            end

            it "filters overridden fields" do
              expect(subject.to_h[:params]).to eq(
                "password" => "some_password",
                "password_confirmation" => "some_password",
                "foo" => "[FILTERED]",
              )
            end
          end
        end
      end
    end

    context "when payload is a String" do
      let(:expected) do
        shared_hash.merge(payload: payload)
      end
      let(:payload) { "damnit" }
      its(:to_h) do
        is_expected.to match(expected)
      end
    end
  end

  describe "#backtrace_to_s" do
    context "without an exception" do
      let(:exception) { nil }

      its(:backtrace_to_s) do
        is_expected.to eq("")
      end
    end

    context "when exception is nested" do
      its(:backtrace_to_s) do
        is_expected.to include("Cause: RuntimeError: Error 1")
      end
    end

    context "when exception isn't nested" do
      let(:exception) do
        begin
          fail exception_message_one
        rescue StandardError => ex
          ex
        end
      end

      its(:backtrace_to_s) do
        is_expected.not_to include("Cause: RuntimeError: Error 1")
      end

      its(:backtrace_to_s) do
        is_expected.to include(Sapience.root)
      end
    end
  end
end
