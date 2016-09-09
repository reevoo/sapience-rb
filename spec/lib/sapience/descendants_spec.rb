require "spec_helper"

describe Sapience::Descendants do
  class DescBase
    extend Sapience::Descendants
  end
  class DescOne < DescBase
  end
  class DescTwo < DescBase
  end
  subject { DescBase}
  its(:descendants) { is_expected.to match_array([DescOne, DescTwo]) }
end