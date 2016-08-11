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
end
