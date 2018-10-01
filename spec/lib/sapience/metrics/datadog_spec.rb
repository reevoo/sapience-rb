# frozen_string_literal: true
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

      context "namespace provided" do
        let(:title) { "my_title" }

        before do
          allow(Sapience).to receive(:app_name).and_return("test_app")
          allow(Sapience).to receive(:environment).and_return("test")
        end

        context "with title option" do
          let(:options_hash) do
            { namespaced_keys: [:title] }
          end

          it "add prefix for the title" do
            expect(statsd).to receive(:event).with("test_app.test.my_title", text, {})
            subject.event(title, text, options_hash)
          end

          context "and custom namespace" do
            let(:options_hash) do
              {
                namespaced_keys: [:title],
                namespace_prefix: "custom_prefix",
              }
            end

            it "add prefix for the title" do
              expect(statsd).to receive(:event).with("custom_prefix.my_title", text, {})
              subject.event(title, text, options_hash)
            end
          end
        end

        context "with namespace option" do
          context "and aggregation_key value" do
            let(:options_hash) do
              { namespaced_keys: [:aggregation_key] }
            end

            context "without aggregation_key option" do
              it "add prefix for the aggregation_key and take text from title" do
                expect(statsd).to receive(:event).with("my_title", text, aggregation_key: "test_app.test.my_title")
                subject.event(title, text, options_hash)
              end
            end

            context "with aggregation_key option" do
              let(:options_hash) do
                {
                  namespaced_keys: [:aggregation_key],
                  aggregation_key: "my_key",
                }
              end

              it "add prefix for the aggregation_key" do
                expect(statsd).to receive(:event).with("my_title", text, aggregation_key: "test_app.test.my_key")
                subject.event(title, text, options_hash)
              end
            end
          end

          context "with aggregation_key and title values" do
            let(:options_hash) do
              { namespaced_keys: %i[title aggregation_key] }
            end

            context "without aggregation_key option" do
              it "add prefix for title and aggregation_key" do
                expect(statsd)
                  .to receive(:event)
                  .with("test_app.test.my_title", text, aggregation_key: "test_app.test.my_title")
                subject.event(title, text, options_hash)
              end
            end

            context "with aggregation_key option" do
              let(:options_hash) do
                {
                  namespaced_keys: %i[title aggregation_key],
                  aggregation_key: "my_key",
                }
              end

              it "add prefix for the title" do
                expect(statsd)
                  .to receive(:event)
                  .with("test_app.test.my_title", text, aggregation_key: "test_app.test.my_key")
                subject.event(title, text, options_hash)
              end
            end
          end
        end
      end
    end
  end

  describe "#success" do
    let(:module_name) { "custom_module_name" }
    let(:action) { "custom_action" }

    context "without options" do
      it "sets correct tags and metric key" do
        expect(statsd).to receive(:increment).with("success", tags: %w(module:custom_module_name action:custom_action))
        subject.success(module_name, action)
      end
    end

    context "with options" do
      let(:hash) do
        { foo: "bar" }
      end

      it "sets correct tags and metric key" do
        expect(statsd)
          .to receive(:increment).with(
            "success",
            foo: "bar",
            tags: %w(module:custom_module_name action:custom_action),
          )
        subject.success(module_name, action, hash)
      end

      context "and tags option provided" do
        let(:hash) do
          { tags: %w(event:my_event) }
        end

        it "sets correct tags" do
          expect(statsd)
            .to receive(:increment).with(
              "success",
              tags: %w(event:my_event module:custom_module_name action:custom_action),
            )
          subject.success(module_name, action, hash)
        end

        context "and module tag exist" do
          let(:hash) do
            { tags: %w(event:my_event module:module_from_option) }
          end

          it "overrides module tag from options" do
            expect(statsd)
              .to receive(:increment).with(
                "success",
                tags: %w(event:my_event module:custom_module_name action:custom_action),
              )
            subject.success(module_name, action, hash)
          end

          it "logs a warning" do
            expect(Sapience.logger).to receive(:warn).with(
                "WARNING: tag 'module' already exist, overwritten with custom_module_name",
              )
            subject.success(module_name, action, hash)
          end
        end

        context "and action tag exist" do
          let(:hash) do
            { tags: %w(event:my_event action:action_from_option) }
          end

          it "overrides module tag from options" do
            expect(statsd)
              .to receive(:increment).with(
                "success",
                tags: %w(event:my_event module:custom_module_name action:custom_action),
              )
            subject.success(module_name, action, hash)
          end

          it "logs a warning" do
            expect(Sapience.logger).to receive(:warn).with(
              "WARNING: tag 'action' already exist, overwritten with custom_action",
            )
            subject.success(module_name, action, hash)
          end
        end
      end
    end
  end
end
