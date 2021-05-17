# frozen_string_literal: true
require "spec_helper"

describe Sapience::Formatters::Json do
  include_context "logs"
  before do
    travel_to Time.new(2015, 9, 10, 20, 13, 45)
    Sapience.configure { |c| c.app_name = "some_tests" }
  end
  after { travel_back }
  let(:formatter) { described_class.new }

  describe "#call" do
    subject(:formatted) do
      json = JSON.parse(formatter.call(log, Sapience[described_class]))
      json.deep_symbolize_keyz!
    end
    let(:payload) { "HEY HO" }

    specify do
      is_expected.to match(
                       app_name: Sapience.app_name,
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
                       environment: Sapience.environment,
                     )
    end

    context "with option 'excluded_fields'" do
      let(:formatter) do
        described_class.new(
                exclude_fields: %i[name level_index line pid thread file host app_name duration],
      )
      end

      specify do
        is_expected.to match(
                         duration_ms: duration,
                         exception: a_hash_including(
                           name: exception.class.name,
                           message: exception_message_two,
                           stack_trace: a_kind_of(Array),
                           ),
                         level: "info",
                         message: message,
                         metric: metric,
                         payload: "HEY HO",
                         tags: tags,
                         timestamp: a_kind_of(String),
                         environment: Sapience.environment,
                         )
      end
    end
  end
end
