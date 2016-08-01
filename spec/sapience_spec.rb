require "spec_helper"

describe Sapience do
  let(:custom_logger_config) do
    {
      default_level: :fatal,
      appenders: [
        appender: :sentry,
      ],
    }
  end

  before { described_class.reset_configuration! }

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

  describe '.configure' do
    it 'overrides the default settings for logger' do
      expect(described_class).to receive(:configure_logger)
      described_class.configure { |config| config[:logger] = custom_logger_config }
      expect(described_class.configuration[:logger]).to eq(custom_logger_config)
    end
  end

  describe '.reset_configuration!' do
    specify do
      described_class.configure { |config| config[:logger] = custom_logger_config }
      expect { described_class.reset_configuration! }
        .to change { described_class.configuration }
        .to(described_class::DEFAULT_CONFIGURATION)
    end
  end

  describe 'configure_logger' do
    specify do
      expect { described_class.configure_logger }
        .to change { SemanticLogger.default_level }.to :trace
    end
  end
end
