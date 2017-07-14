# frozen_string_literal: true
class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :sku, :ean
end
