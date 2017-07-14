# frozen_string_literal: true
require "rails_helper"

RSpec.describe "posts/new", type: :view do
  let(:post) { build :post }
  before(:each) do
    assign(:post, post)
  end

  it "renders new post form" do
    render

    assert_select "form[action=?][method=?]", posts_path, "post" do
      assert_select "input#post_title[name=?]", "post[title]"
      assert_select "input#post_body[name=?]", "post[body]"
    end
  end
end
