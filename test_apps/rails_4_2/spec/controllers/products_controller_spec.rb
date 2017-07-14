# frozen_string_literal: true
require "rails_helper"

describe ProductsController, type: :controller do
  specify do
    expect(subject.logger).to be_a(Sapience::Logger)
  end
end
