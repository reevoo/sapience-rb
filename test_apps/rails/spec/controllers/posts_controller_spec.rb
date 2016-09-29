require "rails_helper"

describe PostsController, type: :controller do
  specify do
    expect(subject.logger).to be_a(Sapience::Logger)
  end
end
