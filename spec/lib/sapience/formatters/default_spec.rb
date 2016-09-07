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
      is_expected.to match(/#{TS_REGEX} I \[\d+:#{thread_name} sapience.rb:(\d+)\] \[tag_one\] \[tag_two\] \(9\.999s\) Alex -- Sapience is really cool -- "HEY HO" -- Exception: RuntimeError: Error 2/) # rubocop:disable LineLength
    end
  end
  # its(:call) do
  #   aggregate_failures "testing call" do
  #     expect(log).to eq("")
  #   end
  # end
end
