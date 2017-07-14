# frozen_string_literal: true
require "spec_helper"

describe Sapience::Metrics do
  subject { described_class.new }
  describe "#timing" do
    specify do
      expect { subject.timing("key", 100, {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#increment" do
    specify do
      expect { subject.increment("key", {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#decrement" do
    specify do
      expect { subject.decrement("key", {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#histogram" do
    specify do
      expect { subject.histogram("key", 100, {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#gauge" do
    specify do
      expect { subject.gauge("key", 100, {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#count" do
    specify do
      expect { subject.count("key", 100, {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#time" do
    specify do
      expect { subject.time("key", {}) }.to raise_error(NotImplementedError)
    end
  end
  describe "#batch" do
    specify do
      expect { subject.batch }.to raise_error(NotImplementedError)
    end
  end

  describe "#event" do
    specify do
      expect { subject.event("key", "Something that happened", {}) }.to raise_error(NotImplementedError)
    end
  end
end
