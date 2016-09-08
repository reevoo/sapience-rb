require "spec_helper"

describe Symbol do
  subject { :some_symbol }
  it { is_expected.to respond_to(:camelize) }

  describe "#camelize" do
    context "when provided true" do
      subject { :some_symbol.camelize(true) }
      it { is_expected.to eq("SomeSymbol") }
    end

    context "when provided false" do
      subject { :some_symbol.camelize(false) }
      it { is_expected.to eq("someSymbol") }
    end

    context "without arguments" do
      subject { :some_symbol.camelize }
      it { is_expected.to eq("SomeSymbol") }
    end
  end
end
