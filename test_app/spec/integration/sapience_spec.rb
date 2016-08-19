require "rails_helper"
require "fileutils"

describe Sapience, "rails integration", :integration do
  context "with a sapience.yml present in config/" do
    describe ".config" do
      subject(:config) { Sapience.config }
      its(:default_level) { is_expected.to eq(:fatal) }
      its(:default_level_index) { is_expected.to eq(5) }
      its(:backtrace_level) { is_expected.to eq(:fatal) }
      its(:backtrace_level_index) { is_expected.to eq(5) }
    end
  end
end