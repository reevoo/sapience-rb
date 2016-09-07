require "spec_helper"

describe Sapience::Formatters::Json do
  include_context "logs"
  before { travel_to Time.new(2015, 9, 10, 20, 13, 45) }
  after { travel_back }
  let(:formatter) { described_class.new }

  describe "#call" do
    subject(:formatted) do
      json = JSON.parse(formatter.call(log, Sapience[described_class]))
      json.deep_symbolize_keys!
    end
    let(:payload) { "HEY HO" }

    specify do
      is_expected.to match(
        application: "Sapience",
        duration: "9.999s",
        duration_ms: duration,
        exception: a_hash_including(
          name: exception.class.name,
          message: exception_message_two,
          stack_trace: a_kind_of(Array),
        ),
        file: a_string_ending_with("/sapience.rb"),
        host: a_kind_of(String),
        level: "info",
        level_index: 2,
        line: a_kind_of(Integer),
        message: message,
        metric: metric,
        payload: "HEY HO",
        name: name,
        pid: a_kind_of(Integer),
        tags: tags,
        thread: thread_name,
        timestamp: a_kind_of(String),
    )
    end
  end
end
