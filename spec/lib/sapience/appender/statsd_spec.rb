require "spec_helper"
describe Sapience::Appender::Statsd do
  subject { described_class.new(options) }

  let(:url) { "udp://0.0.0.0:2222" }
  let(:options) do
    {
      url: url,
    }
  end

  context "without url" do
    let(:url) { nil }

    it "sets the default url" do
      expect(::Statsd).to receive(:new).with("localhost", 8125)
      subject
    end
  end

  context "with url provided" do
    it "sets the url" do
      expect(::Statsd).to receive(:new).with("0.0.0.0", 2222)
      subject
    end
  end

  describe "#log" do
    let(:metric) { "my/own/metric" }
    let(:duration) { nil }
    let(:metric_amount) { nil }

    let(:log) do
      LogFactory.build(
        metric: metric,
        duration: duration,
        metric_amount: metric_amount,
      )
    end
    let(:statsd) { instance_spy(::Statsd) }

    before do
      allow(::Statsd).to receive(:new).and_return(statsd)
    end

    context "without metric" do
      let(:metric) { nil }

      it "returns nil" do
        expect(subject.log(log)).to eq(nil)
      end

      it "doesn't call statsd" do
        expect(statsd).not_to receive(:timing)
        expect(statsd).not_to receive(:decrement)
        expect(statsd).not_to receive(:increment)
        subject.log(log)
      end
    end

    context "with duration" do
      let(:duration) { 200 }

      it "calls timing" do
        expect(statsd).to receive(:timing).with(metric, duration)
        expect(subject.log(log)).to eq(true)
      end

      it "doesn't increment or decrement" do
        expect(statsd).not_to receive(:decrement)
        expect(statsd).not_to receive(:increment)
        subject.log(log)
      end

      it "returns true" do
        expect(subject.log(log)).to eq(true)
      end
    end

    context "without duration" do
      context "without metric_amount" do
        it "increment by 1" do
          expect(statsd).to receive(:increment).with(metric).once
          expect(subject.log(log)).to eq(true)
        end
      end

      context "metric_amount is negative" do
        let(:metric_amount) { -2 }

        it "decrement by 2" do
          expect(statsd).to receive(:decrement).with(metric).twice
          expect(subject.log(log)).to eq(true)
        end
      end

      context "metric_amount is negative" do
        let(:metric_amount) { 3 }

        it "increment by 3" do
          expect(statsd).to receive(:increment).with(metric).exactly(3).times
          expect(subject.log(log)).to eq(true)
        end
      end
    end

  end
end
