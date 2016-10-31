require "spec_helper"
require "sapience/extensions/active_record/model_metrics"

describe Sapience::Extensions::ActiveRecord::ModelMetrics do
  module Namespace
    class CustomRecord
      include Sapience::Extensions::ActiveRecord::ModelMetrics
    end
  end

  describe "constants" do
    specify "MODEL_CREATE_METRICS_KEY constant is set" do
      expect(Namespace::CustomRecord::SAPIENCE_MODEL_CREATE_METRICS_KEY).to eq("model.namespace.custom_record.create")
    end

    specify "MODEL_UPDATE_METRICS_KEY constant is set" do
      expect(Namespace::CustomRecord::SAPIENCE_MODEL_UPDATE_METRICS_KEY).to eq("model.namespace.custom_record.update")
    end

    specify "MODEL_DESTROY_METRICS_KEY constant is set" do
      expect(Namespace::CustomRecord::SAPIENCE_MODEL_DESTROY_METRICS_KEY).to eq("model.namespace.custom_record.destroy")
    end
  end

  describe "class methods" do
    subject { Namespace::CustomRecord }

    its(:tableized_name) do
      is_expected.to eq("namespace.custom_record")
    end
  end

  describe "instance methods" do
    subject { Namespace::CustomRecord.new }

    its(:tableized_name) do
      is_expected.to eq("namespace.custom_record")
    end
  end
end
