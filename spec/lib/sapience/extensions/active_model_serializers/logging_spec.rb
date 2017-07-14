# frozen_string_literal: true
require "spec_helper"
require "active_model_serializers"
require "active_model_serializers/logging"
require "sapience/extensions/active_model_serializers/logging"

describe ActiveModelSerializers::Logging do
  class LoggingTest
    include ActiveModelSerializers::Logging
  end
  subject { LoggingTest.new }

  describe "#tag_logger" do
    context "when given a block" do
    end

    context "when given no block" do
      specify do
        expect { subject.send(:tag_logger, ["test"]) }.to raise_error(LocalJumpError)
      end
    end
  end
end
