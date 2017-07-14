# frozen_string_literal: true
require "rails_helper"

RSpec.describe "posts/show", type: :view do
  let(:post) { create(:post, title: "Title", body: "Body") }
  before(:each) do
    @post = assign(:post, post)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Body/)
  end
end
