# frozen_string_literal: true
class Todo < ActiveRecord::Base
  belongs_to :list
  attr_accessible :name
end
