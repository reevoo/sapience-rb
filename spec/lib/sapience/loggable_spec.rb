require "spec_helper"

describe Sapience::Loggable do
  class TestClass
  end

  describe "when included" do
    before(:all) do
      TestClass.send(:include, described_class) unless TestClass.ancestors.include?(described_class)
    end

    specify do
      expect(TestClass.ancestors).to include(SemanticLogger::Loggable)
    end

    describe "class methods" do
      subject { TestClass }
      specify { expect(subject).to respond_to(:logger) }
    end

    describe "instance methods" do
      subject { TestClass.new }
      specify { expect(subject).to respond_to(:logger) }
    end
  end
end
