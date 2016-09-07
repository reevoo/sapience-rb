require "spec_helper"
require "sapience/core_ext/hash"

describe Hash do
  describe "#deep_symbolize_keys!" do
    subject do
      {
        "one" => {
          "two" => [
            "three" => "val"
          ]
        }
      }
    end

    let(:expected_hash) do
      {
        one: {
          two: [
            three: "val"
          ]
        }
      }
    end

    it "sybolizes string keys" do
      expect { subject.deep_symbolize_keys! }
        .to change { subject }
        .to(
          {
            one: {
              two: [
                three: "val"
              ]
            }
          }
        )
    end
  end
end
