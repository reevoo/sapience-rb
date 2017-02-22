class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :sku, :ean
end
