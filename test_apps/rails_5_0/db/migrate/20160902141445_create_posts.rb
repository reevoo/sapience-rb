# frozen_string_literal: true
class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :body
      t.belongs_to :author, foreign_key: {
        to_table: :users,
        column: :author_id,
        name: :posts_author_fk,
        on_delete: :cascade,
        on_update: :restrict,
      }

      t.timestamps
    end
  end
end
