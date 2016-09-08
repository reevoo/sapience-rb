require "spec_helper"

describe Thread do
  subject(:thread) do
    Thread.new do
      # no op
    end
  end
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:name=) }

  describe '#name=' do
    specify do
      expect { subject.name = :test }
        .to change { subject.name }.to "test"
    end
  end
end