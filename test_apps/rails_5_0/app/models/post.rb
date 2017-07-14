# frozen_string_literal: true
class Post < ApplicationRecord
  include Sapience::Extensions::ActiveRecord::ModelMetrics
  belongs_to :author, class_name: User, inverse_of: :posts
end
