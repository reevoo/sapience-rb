# frozen_string_literal: true
require "spec_helper"
require "sapience/core_ext/hash"

describe Hash do
  describe "#deep_symbolize_keyz!" do
    subject do
      {
        "one" => {
          "two" => [
            "three" => "val",
          ],
        },
      }
    end

    let(:expected_hash) do
      {
        one: {
          two: [
            three: "val",
          ],
        },
      }
    end

    it "sybolizes string keys" do
      expect { subject.deep_symbolize_keyz! }
        .to change { subject }
        .to(
            one: {
              two: [
                three: "val",
              ],
            },
        )
    end
  end
end
