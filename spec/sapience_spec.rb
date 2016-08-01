require "spec_helper"

describe Sapience do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  describe '.configuration' do
    describe ':logger' do
      subject { described_class.configuration }
      its([:logger]) do
        is_expected.to eq(
          default_level: :trace,
          appenders: [
            { io: STDOUT, formatter: :json },
            { appender: :sentry },
          ],
        )
      end

      its([:metrics]) do
        is_expected.to eq(
          url: "udp://localhost:8125",
        )
      end
    end
  end

  describe 'configure_logger' do
    specify do
      expect { described_class.configure_logger }
        .to change { SemanticLogger.default_level }.to :trace
    end
  end
end
