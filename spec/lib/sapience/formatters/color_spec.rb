require "spec_helper"

describe Sapience::Formatters::Color do
  include_context "logs"
  before { travel_to Time.new(2015, 9, 10, 20, 13, 45) }
  after { travel_back }
  let(:formatter) { described_class.new }

  describe "#call" do
    subject(:formatted) { formatter.call(log, nil) }
    let(:payload) { "HEY HO" }

    specify do
      is_expected
        .to start_with(
          "2015-09-10 20:13:45.000000" \
          " \e[36mI\e[0m" \
          " [#{$PROCESS_ID}:#{thread_name} sapience.rb:10]" \
          " [\e[36mtag_one\e[0m] [\e[36mtag_two\e[0m]" \
          " (\e[1m9.999s\e[0m) \e[36mAlex\e[0m" \
          " -- Sapience is really cool" \
          " -- \"HEY HO\"" \
          " -- Exception: \e[1mRuntimeError: Error 2\e[0m\n",
        )
    end
  end
end
