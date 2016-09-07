require "spec_helper"

describe Sapience::Formatters::Default do
  include_context "logs"
  before { travel_to Time.new(2015, 9, 10, 20, 13, 45) }
  after { travel_back }
  let(:formatter) { described_class.new }

  describe "#call" do
    subject(:formatted) { formatter.call(log, nil) }
    let(:payload) { "HEY HO" }

    specify do
      is_expected.to start_with(
        "2015-09-10 20:13:45.000000 I [#{$PROCESS_ID}:#{thread_name} sapience.rb:10]" \
        " [tag_one] [tag_two] (9.999s) Alex -- Sapience is really cool" \
        " -- \"HEY HO\" -- Exception: RuntimeError: Error 2",
      )
    end
  end
end
