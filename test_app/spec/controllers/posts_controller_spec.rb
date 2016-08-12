require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  specify do
    expect(subject.logger).to be_a(Sapience::Logger)
  end
end
