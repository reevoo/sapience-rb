require "spec_helper"
describe Sapience::Metrics::Datadog do
  subject { described_class.new(options) }

  let(:url) { "udp://0.0.0.0:2222" }
  let(:tags) { nil }
  let(:options) do
    {
      url:  url,
      tags: tags,
    }
  end

  let(:statsd) { instance_spy(::Datadog::Statsd) }
  let(:metric) { "my/own/metric" }

  before do
    allow(Sapience).to receive(:environment).and_return("rspec")
    allow(::Datadog::Statsd).to receive(:new).and_return(statsd)
    allow(statsd).to receive(:batch).and_yield
  end

  describe "#valid?" do
    context "when uri scheme is udp" do
      its(:valid?) do
        is_expected.to eq(true)
      end
    end

    context "when uri scheme is not udp" do
      let(:url) { "https://0.0.0.0:2222" }
      its(:valid?) do
        is_expected.to eq(false)
      end
    end
  end

  describe "#provider" do
    context "without url" do
      let(:url) { nil }

      it "sets the default url" do
        expect(::Datadog::Statsd)
          .to receive(:new)
          .with("localhost", 8125, namespace: "sapience_rspec.rspec", tags: nil)
        subject.provider
      end
    end

    context "with url provided" do
      it "sets the url" do
        expect(::Datadog::Statsd)
          .to receive(:new)
          .with("0.0.0.0", 2222, namespace: "sapience_rspec.rspec", tags: nil)
        subject.provider
      end
    end

    context "with tags provided" do
      let(:tags) { "tag1:true" }
      it "sets the url" do
        expect(::Datadog::Statsd)
          .to receive(:new)
          .with("0.0.0.0", 2222, namespace: "sapience_rspec.rspec", tags: tags)
        subject.provider
      end
    end
  end

  describe "#timing" do
    let(:duration) { 200 }

    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.timing(metric, duration)).to eq(false)
      end
    end

    it "calls timing" do
      expect(statsd).to receive(:timing).with(metric, duration, {})
      subject.timing(metric, duration)
    end

    context "when provided a block" do
      it "calls timing" do
        expect(statsd).to receive(:timing) do |_metric, duration|
          expect(duration).to be >= 500
        end

        subject.timing(metric) do
          sleep 0.5
        end
      end
    end
  end

  describe "#increment" do
    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.increment(metric)).to eq(false)
      end
    end

    context "without options" do
      it "increment by 1" do
        expect(statsd).to receive(:increment).with(metric, {})
        subject.increment(metric)
      end
    end

    context "with options" do
      let(:hash) do
        { foo: "bar" }
      end

      it "increment by 1" do
        expect(statsd).to receive(:increment).with(metric, hash)
        subject.increment(metric, hash)
      end
    end
  end

  describe "#decrement" do
    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.decrement(metric)).to eq(false)
      end
    end

    context "without options" do
      it "decrements" do
        expect(statsd).to receive(:decrement).with(metric, {})
        subject.decrement(metric)
      end
    end

    context "with options" do
      let(:hash) do
        { foo: "bar" }
      end

      it "decrement with options provided" do
        expect(statsd).to receive(:decrement).with(metric, hash)
        subject.decrement(metric, hash)
      end
    end
  end

  describe "#histogram" do
    let(:metric_amount) { 444 }

    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.histogram(metric, metric_amount)).to eq(false)
      end
    end

    it "calls timing" do
      expect(statsd).to receive(:histogram).with(metric, metric_amount, {})
      subject.histogram(metric, metric_amount)
    end
  end

  describe "#count" do
    let(:metric_amount) { 33 }

    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.count(metric, metric_amount)).to eq(false)
      end
    end

    it "calls count" do
      expect(statsd).to receive(:count).with(metric, metric_amount, {})
      subject.count(metric, metric_amount)
    end
  end

  describe "#time" do
    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.time(metric)).to eq(false)
      end
    end

    it "calls count" do
      expect(statsd).to receive(:time).with(metric, {}).and_yield
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

    context "when not valid?" do
      let(:url) { "https://0.0.0.0:2222" }
      specify do
        expect(subject.gauge(metric, metric_amount, hash)).to eq(false)
      end
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
      expect(statsd).to receive(:increment).with(metric, hash)

      subject.batch do
        subject.gauge(metric, metric_amount, hash)
        subject.increment(metric, hash)
      end
    end
  end

  describe "#event" do
    let(:title) { "Some Title" }
    let(:text) { "Some Text" }
    let(:options_hash) { nil }

    context "without options" do
      it "emit event" do
        expect(statsd).to receive(:event).with(title, text, {})
        subject.event(title, text, options_hash)
      end
    end

    context "with options" do
      let(:options_hash) do
        { foo: "bar" }
      end

      it "emit event with options" do
        expect(statsd).to receive(:event).with(title, text, foo: "bar")
        subject.event(title, text, options_hash)
      end

      context "namespace = true" do
        let(:options_hash) do
          { namespace: true }
        end
        let(:title) { "my_title" }

        before do
          allow(Sapience).to receive(:app_name).and_return("test_app")
          allow(Sapience).to receive(:environment).and_return("test")
        end

        it "add prefix for the title" do
          expect(statsd).to receive(:event).with("test_app.test.my_title", text, {})
          subject.event(title, text, options_hash)
        end
      end
    end
  end
end
