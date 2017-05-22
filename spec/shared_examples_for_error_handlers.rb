RSpec.shared_examples "error handler" do
  %w(capture_exception capture capture! capture_message user_context tags_context).each do |m|
    it "responds to #{m}" do
      expect(subject).to respond_to(m.to_sym)
    end
  end
end
