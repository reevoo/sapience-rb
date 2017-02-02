class List < ActiveRecord::Base
  has_many :todos

  include Sapience::Extensions::ActiveRecord::ModelMetrics

  attr_accessible :description, :name, :position
end
