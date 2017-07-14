# frozen_string_literal: true
require "spec_helper"
require "action_cable/engine"
require "sapience/extensions/action_cable/tagged_logger_proxy"

describe ActionCable::Connection::TaggedLoggerProxy do
  subject { described_class.new(logger, tags: proxy_tags) }

  describe "#tag" do
    let(:logger) { Sapience[described_class] }
    let(:logger_tags) { %w(one two) }
    let(:proxy_tags) { %w(one three) }
    let(:expected_tags) { proxy_tags - logger_tags }

    before do
      allow(logger).to receive(:tags).and_return(logger_tags)
      allow(subject).to receive(:tags).and_return(proxy_tags)
    end

    it "logs only uniq tags" do
      expect(logger).to receive(:tagged).with(*expected_tags, any_args)
      subject.tag(logger)
    end
  end
end
