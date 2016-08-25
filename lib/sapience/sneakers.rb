require "sapience"

module Sneakers
  module Worker
    def self.descendants # :nodoc:
      descendants = []
      ObjectSpace.each_object(singleton_class) do |k|
        descendants.unshift k unless k == self
      end
      descendants
    end
  end
end

module Sapience
  module Sneakers
    ::Sneakers::Worker.descendants.each do |worker|
      worker.send(:include, Sapience::Loggable)
    end
  end
end
