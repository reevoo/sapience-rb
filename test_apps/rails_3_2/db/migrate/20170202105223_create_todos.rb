class CreateTodos < ActiveRecord::Migration
  def change
    create_table :todos do |t|
      t.string :name, null: false
      t.belongs_to :list, null: false

      t.timestamps
    end

    add_index :todos, :list_id, name: "todos_on_list_id_idx"
  end
end
