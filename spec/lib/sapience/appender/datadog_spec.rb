require "spec_helper"
describe Sapience::Appender::Datadog do
  subject { described_class.new(options) }

  let(:url) { "udp://0.0.0.0:2222" }
  let(:tags) { nil }
  let(:options) do
    {
      url:  url,
      tags: tags,
    }
  end

  let(:statsd) { instance_spy(::Statsd) }
  let(:metric) { "my/own/metric" }

  before do
    allow(::Statsd).to receive(:new).and_return(statsd)
    allow(statsd).to receive(:batch).and_yield
  end

  describe "#provider" do
    context "without url" do
      let(:url) { nil }

      it "sets the default url" do
        expect(::Statsd).to receive(:new).with("localhost", 8125, tags: nil)
        subject.provider
      end
    end

    context "with url provided" do
      it "sets the url" do
        expect(::Statsd).to receive(:new).with("0.0.0.0", 2222, tags: nil)
        subject.provider
      end
    end

    context "with tags provided" do
      let(:tags) { "tag1:true" }
      it "sets the url" do
        expect(::Statsd).to receive(:new).with("0.0.0.0", 2222, tags: "tag1:true")
        subject.provider
      end
    end
  end

  describe "#log" do
    let(:duration) { nil }
    let(:metric_amount) { nil }

    let(:log) do
      LogFactory.build(
        metric:        metric,
        duration:      duration,
        metric_amount: metric_amount,
      )
    end

    context "without metric" do
      let(:metric) { nil }

      it "returns nil" do
        expect(subject.log(log)).to eq(false)
      end

      it "doesn't call statsd" do
        expect(subject).not_to receive(:timing)
        expect(subject).not_to receive(:decrement)
        expect(subject).not_to receive(:increment)
        subject.log(log)
      end
    end

    context "with duration" do
      let(:duration) { 200 }

      it "calls timing" do
        expect(subject).to receive(:timing).with(metric, duration)
        expect(subject.log(log)).to eq(true)
      end

      it "doesn't increment or decrement" do
        expect(subject).not_to receive(:decrement)
        expect(subject).not_to receive(:increment)
        subject.log(log)
      end

      it "returns true" do
        expect(subject.log(log)).to eq(true)
      end
    end

    context "without duration" do
      context "without metric_amount" do
        it "increment by 1" do
          expect(subject).to receive(:increment).with(metric, 1)
          expect(subject.log(log)).to eq(true)
        end
      end

      context "metric_amount is negative" do
        let(:metric_amount) { -2 }

        it "decrement by 2" do
          expect(subject).to receive(:decrement).with(metric, 2)
          expect(subject.log(log)).to eq(true)
        end
      end

      context "metric_amount is negative" do
        let(:metric_amount) { 3 }

        it "increment by 3" do
          expect(subject).to receive(:increment).with(metric, metric_amount)
          expect(subject.log(log)).to eq(true)
        end
      end
    end
  end

  describe "#timing" do
    let(:duration) { 200 }

    it "calls timing" do
      expect(statsd).to receive(:timing).with(metric, duration)
      subject.timing(metric, duration)
    end

    context 'when provided a block' do
      it 'calls timing' do
        expect(statsd).to receive(:timing) do |metric, duration|
          expect(duration).to be >= 500
        end

        subject.timing(metric) do
          sleep 0.5
        end
      end
    end
  end

  describe "#increment" do
    context "without metric_amount" do
      it "increment by 1" do
        expect(statsd).to receive(:increment).with(metric).once
        subject.increment(metric)
      end
    end

    context "with metric_amount" do
      let(:metric_amount) { 2 }

      it "increment by 1" do
        expect(statsd).to receive(:increment).with(metric).twice
        subject.increment(metric, metric_amount)
      end
    end
  end

  describe "#decrement" do
    context "without metric_amount" do
      it "decrement by 1" do
        expect(statsd).to receive(:decrement).with(metric).once
        subject.decrement(metric)
      end
    end

    context "with metric_amoun" do
      let(:metric_amount) { 2 }

      it "decrement by 2" do
        expect(statsd).to receive(:decrement).with(metric).twice
        subject.decrement(metric, metric_amount)
      end
    end
  end

  describe "#histogram" do
    let(:metric_amount) { 444 }

    it "calls timing" do
      expect(statsd).to receive(:histogram).with(metric, metric_amount)
      subject.histogram(metric, metric_amount)
    end
  end

  describe "#count" do
    let(:metric_amount) { 33 }

    it "calls count" do
      expect(statsd).to receive(:count).with(metric, metric_amount, {})
      subject.count(metric, metric_amount)
    end
  end

  describe "#time" do
    it "calls count" do
      expect(statsd).to receive(:time).with(metric).and_yield
      subject.time(metric) do
        sleep 0.5
      end
    end
  end

  describe "#gauge" do
    let(:metric_amount) { 444 }
    let(:hash) do
      {
        foo: "bar",
      }
    end

    it "calls gauge" do
      expect(statsd).to receive(:gauge).with(metric, metric_amount, hash)

      subject.gauge(metric, metric_amount, hash)
    end
  end

  describe "#batch" do
    let(:metric_amount) { 444 }
    let(:hash) do
      {
        foo: "bar",
      }
    end

    it "calls batch" do
      expect(statsd).to receive(:gauge).with(metric, metric_amount, hash)
      expect(statsd).to receive(:increment).with(metric)

      subject.batch do |s|
        s.gauge(metric, metric_amount, hash)
        s.increment(metric)
      end
    end
  end
end
