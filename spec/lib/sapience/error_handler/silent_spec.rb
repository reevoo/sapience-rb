# frozen_string_literal: true
require "spec_helper"
require "shared_examples_for_error_handlers"

describe Sapience::ErrorHandler::Silent do
  subject { described_class.new }

  it_behaves_like "error handler"
end
