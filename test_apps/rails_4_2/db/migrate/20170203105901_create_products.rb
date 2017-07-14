# frozen_string_literal: true
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.string :ean

      t.timestamps null: false
    end
  end
end
