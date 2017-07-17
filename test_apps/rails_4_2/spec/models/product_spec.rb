# frozen_string_literal: true
require "rails_helper"

describe Product, type: :model do
  let!(:metrics) { Sapience.metrics }
  let(:tags) { %w(query:product.load) }

  before(:each) { create :product }

  it "records som sql metrics" do
    expect(metrics).to receive(:increment).with("activerecord.sql", tags: tags)
    expect(metrics).to receive(:timing).with("activerecord.sql.time", kind_of(Float), tags: tags)
    Product.first
  end

  describe "callbacks" do
    before do
      allow(Sapience.metrics).to receive(:increment).and_call_original
    end

    describe "#before_create" do
      it "increments counter" do
        expect(Sapience.metrics)
          .to receive(:increment)
          .with(described_class::SAPIENCE_MODEL_CREATE_METRICS_KEY)
        create(:product)
      end
    end

    describe "#before_update" do
      it "increments counter" do
        review_email = create(:product)
        expect(Sapience.metrics)
          .to receive(:increment)
          .with(described_class::SAPIENCE_MODEL_UPDATE_METRICS_KEY)
        review_email.update_attributes! name: "My Product", sku: "whasdasdasda", ean: "88800119283342"
      end
    end

    describe "#before_destroy" do
      subject { create(:product) }
      it "increments counter" do
        expect(Sapience.metrics)
          .to receive(:increment)
          .with(described_class::SAPIENCE_MODEL_DESTROY_METRICS_KEY)
        subject.destroy
      end
    end
  end
end
