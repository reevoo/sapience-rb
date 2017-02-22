class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists do |t|
      t.string :name, null: false
      t.string :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
