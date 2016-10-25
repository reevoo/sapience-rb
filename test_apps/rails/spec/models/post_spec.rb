require "rails_helper"

RSpec.describe Post, type: :model do
  let!(:metrics) { Sapience.metrics }
  let(:tags) { %w(query:post.load) }

  before(:each) {  create :post }

  it "records som sql metrics" do
    expect(metrics).to receive(:increment).with("activerecord.sql", tags: tags)
    expect(metrics).to receive(:timing).with("activerecord.sql.time", kind_of(Float), tags: tags)
    Post.first
  end
end
