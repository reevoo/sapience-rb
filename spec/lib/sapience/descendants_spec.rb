require "spec_helper"

describe Sapience::Descendants do
  class Base
    extend Sapience::Descendants
  end
  class ChildOne < Base
  end
  class ChildTwo < Base
  end
  subject { Base }
  its(:descendants) { is_expected.to match_array([ChildOne, ChildTwo]) }
end