require "spec_helper"

describe Sapience do
  # let(:custom_logger_config) do
  #   {
  #     default_level: :fatal,
  #     appender:      [
  #       appender: :sentry,
  #     ],
  #   }
  # end

  # it "has a version number" do
  #   expect(described_class::VERSION).not_to be nil
  # end

  describe ".config" do
    subject { described_class.config }

    context "no custom configuration" do
      it { is_expected.to be_a(Sapience::Configuration) }
    end

    context "with custom configuration" do
    end

    # describe ":logger" do
    # subject { described_class.configuration }
    # its([:logger]) do
    #   is_expected.to eq(
    #                    default_level: :trace,
    #                    appender:      [
    #       { io: STDOUT, formatter: :json },
    #       { appender: :sentry },
    #     ],
    #   )
    # end
    #
    # its([:metrics]) do
    #   is_expected.to eq(
    #     url: "udp://localhost:8125",
    #   )
    # end
    # end
  end

  describe ".add_appender" do
    subject(:add_appender) { described_class.add_appender(appender, options) }

    after do
      Sapience.remove_appender(subject) if options.is_a?(Hash)
    end

    context "when options is not a Hash" do
      let(:appender) { :file }
      let(:options) { 1 }
      specify { expect { add_appender }.to raise_error(ArgumentError, "options should be a hash") }
    end



    context "when appender is :file" do
      let(:appender) { :file }

      context "and options has :io key present" do
        let(:options) do
          {
            io:        STDOUT,
            formatter: :color,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::File) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Color) }
      end

      context "and options has :file_name key present" do
        let(:options) do
          {
            file_name: "log/sapience.log",
            formatter: :json,
          }
        end

        it { is_expected.to be_a(Sapience::Appender::File) }
        its(:formatter) { is_expected.to be_a(Sapience::Formatters::Json) }
      end
    end

    context "when :statsd key is present" do
      let(:appender) { :datadog }
      let(:options) do
        {
          url: "udp://localhost:2222",
        }
      end

      it { is_expected.to be_a(Sapience::Appender::Datadog) }
    end

    context "when :sentry key is present" do
      let(:appender) { :sentry }
      let(:options) do
        {
          level: :info,
          dsn: "https://foobar:443",
        }
      end

      it { is_expected.to be_a(Sapience::Appender::Sentry) }
    end
  end
end
