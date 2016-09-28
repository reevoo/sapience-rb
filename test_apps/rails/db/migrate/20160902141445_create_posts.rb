class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :body
      t.belongs_to :author # TODO: fix foreign key, foreign_key:

      t.timestamps
    end
  end
end
