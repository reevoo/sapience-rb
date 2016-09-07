require "spec_helper"
require "active_model_serializers"

describe ActiveModelSerializers::Logging do
  class LoggingTest
    include ActiveModelSerializers::Logging
  end
  subject { LoggingTest.new }

  describe "#tag_logger" do
    context "when given a block" do
      specify do
        expect { subject.send(:tag_logger, ["test"]) }.to raise_error(LocalJumpError)
      end
    end

    context "when given no block" do
      # specify do
      #   proc = ->{ puts "inside" }
      #   expect(subject.send(:tag_logger, ['test']), &proc)).not_to raise_error
      # end
    end
  end
end
