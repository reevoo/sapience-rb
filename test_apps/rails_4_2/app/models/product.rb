# frozen_string_literal: true
class Product < ActiveRecord::Base
  include Sapience::Extensions::ActiveRecord::ModelMetrics
end
