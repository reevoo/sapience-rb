class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :body
      t.belongs_to :author, foreign_key: { name: :posts_users_fk }

      t.timestamps
    end
  end
end
