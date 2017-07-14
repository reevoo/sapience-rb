# frozen_string_literal: true
require "spec_helper"

describe Sapience::Base do
  describe ".new" do
    subject { described_class.new(klass) }

    context "when klass is a string" do
      let(:klass) { "TestString" }

      its(:name) { is_expected.to eq("TestString") }
    end

    context "when klass responds to name" do
      class TestClass
        def self.name
          "ClassTest"
        end
      end

      let(:klass) { TestClass }
      its(:name) { is_expected.to eq("ClassTest") }

      context "when klass is an instance of something" do
        let(:klass) { TestClass.new }
        its(:name) { is_expected.to eq("ClassTest") }
      end
    end
  end
end
