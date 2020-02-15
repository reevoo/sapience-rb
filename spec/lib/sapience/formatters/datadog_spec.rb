# frozen_string_literal: true
require "spec_helper"
require "ddtrace"

describe Sapience::Formatters::Datadog do
  include_context "logs"
  before do
    Sapience.configure { |c| c.app_name = "some_tests" }
    Datadog.configure { |c| c.tracer(enabled: false) } # don't send data to dd-agent
  end

  let(:formatter) { described_class.new }

  describe "it inherits Sapience::Formatters::JSON" do
    it { expect(described_class).to be < Sapience::Formatters::Json }
  end

  context "with an active trace span" do
    before { ::Datadog.tracer.trace("my.operation") }
    after { ::Datadog.tracer.active_span.finish }

    describe "#call" do
      subject(:formatted) do
        json = JSON.parse(formatter.call(log, Sapience[described_class]))
        json.deep_symbolize_keyz!
      end
      let(:payload) { "HEY HO" }

      specify do
        is_expected.to include(
                           trace_id: ::Datadog.tracer.active_correlation.trace_id,
                           span_id: ::Datadog.tracer.active_correlation.span_id,
                       )
      end
    end
  end

  context "without a trace span" do
    describe "#call" do
      subject(:formatted) do
        json = JSON.parse(formatter.call(log, Sapience[described_class]))
        json.deep_symbolize_keyz!
      end
      let(:payload) { "HEY HO" }

      specify do
        is_expected.to include(trace_id: 0, span_id: 0)
      end
    end
  end
end
