require "rails_helper"

RSpec.describe "posts/index", type: :view do
  let(:posts) { [create(:post, title: "Title", body: "Body"), create(:post)] }
  before(:each) do
    assign(:posts, posts)
  end

  it "renders a list of posts" do
    render
    assert_select "tr>td", text: "Title", count: 1
    assert_select "tr>td", text: "Body", count: 1

    assert_select "tr>td", text: "This is a post", count: 1
    assert_select "tr>td", text: "It has a lot of content", count: 1
  end
end
