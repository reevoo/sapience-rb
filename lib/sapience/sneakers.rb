require "sapience"

module Sneakers
  module Worker
    extend Sapience::Descendants
  end
end

module Sapience
  module Sneakers
    ::Sneakers::Worker.descendants.each do |worker|
      worker.send(:include, Sapience::Loggable)
    end
  end
end
