class Product < ActiveRecord::Base
  include Sapience::Extensions::ActiveRecord::ModelMetrics
end
