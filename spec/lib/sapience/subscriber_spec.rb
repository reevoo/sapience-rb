require "spec_helper"

describe Sapience::Subscriber do
  let(:appender_options) do
    {
      io: STDOUT,
      formatter: formatter,
    }
  end
  let(:formatter) { nil }
  let(:appender) { Sapience::Appender::Stream.new(appender_options) }
  subject { appender }

  describe "#extract_formatter" do
    context "when formatter is a string" do
      let(:formatter) { "raw" }
      its(:formatter) { is_expected.to be_a(Sapience::Formatters::Raw) }
    end

    context "when formatter is a symbol" do
      let(:formatter) { :color }
      its(:formatter) { is_expected.to be_a(Sapience::Formatters::Color) }
    end

    context "when formatter is a hash" do
      let(:formatter) { { json: {} } }
      its(:formatter) { is_expected.to be_a(Sapience::Formatters::Json) }
    end

    context "when formatter respond call" do
      let(:formatter) { ->() { puts "hey ho" } }
      its(:formatter) { is_expected.to eq(formatter) }
    end

    context "when appender respond to call" do
      class SubscriberWithCall < Sapience::Subscriber
        def call(*_args)
          puts "hey ho"
        end
      end

      subject { SubscriberWithCall.new }

      its(:formatter) { is_expected.to eq(subject) }
    end

    context "when formatter is nil" do
      let(:formatter) { nil }
      its(:formatter) { is_expected.to be_a(Sapience::Formatters::Default) }
    end
  end
end
