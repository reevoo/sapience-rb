require "spec_helper"
require "sapience/extensions/grape/request_format_helper"

describe Sapience::Extensions::Grape::RequestFormatHelper do
  include described_class

  describe "#request_format" do
    let(:content_type) { "application/json" }
    let(:env) do
      { "CONTENT_TYPE" => content_type }
    end

    specify do
      expect(request_format(env)).to eq("json")
    end

    context "with CONTENT-TYPE of application/json" do
      let(:env) do
        { "CONTENT-TYPE" => content_type }
      end

      specify do
        expect(request_format(env)).to eq("json")
      end
    end
  end
end
