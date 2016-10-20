require "spec_helper"
require "rails"
require "sapience/extensions/active_record/log_subscriber"

describe Sapience::Extensions::ActiveRecord::LogSubscriber do
  let(:name) { "Sample" }
  let(:sql) { "SELECT 1+1;" }
  let(:exception) { nil }
  let(:success_payload) do
    {
      name: name,
      sql:  sql,
    }
  end
  let(:payload) { success_payload.dup }
  let(:logger) { Sapience[described_class] }
  let(:duration) { 1_000 }
  let(:event) do
    instance_spy(ActiveSupport::Notifications::Event, payload: payload, duration: duration)
  end

  describe "#identity" do
    before do
      allow(subject).to receive(:logger).and_return(logger)
    end

    it "logs data" do
      expected = {
        name:     name,
        sql:      sql,
        duration: 1000.0,
        tags:     ["request"],
      }

      expect(subject).to receive(:debug).with(expected)
      subject.identity(event)
    end

    context "with exception" do
      let(:exception) { ::RuntimeError.new("TestException") }
      let(:success_payload) do
        {
          name:      name,
          sql:       "SELECT 1+1;",
          exception: exception,
        }
      end

      it "logs data with exception" do
        expected = {
          name:      name,
          sql:       sql,
          duration:  1000.0,
          tags:      %w(request exception),
          exception: exception,
        }

        expect(subject).to receive(:debug).with(expected)
        subject.identity(event)
      end
    end

    context "when the name is SCHEMA" do
      let(:name) { "SCHEMA" }

      it "doesn't log an event" do
        expect(logger).to_not receive(:<<)
        expect(subject).to_not receive(:debug)
        subject.identity(event)
      end
    end
  end
end
