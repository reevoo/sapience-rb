require "rails_helper"

RSpec.describe "posts/edit", type: :view do
  let(:post) { create(:post, title: "Title", body: "Body") }
  before(:each) do
    @post = assign(:post, post)
  end

  it "renders the edit post form" do
    render

    assert_select "form[action=?][method=?]", post_path(@post), "post" do
      assert_select "input#post_title[name=?]", "post[title]"
      assert_select "input#post_body[name=?]", "post[body]"
    end
  end
end
