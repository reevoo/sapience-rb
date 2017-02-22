class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :username
      t.string :email

      t.timestamps
    end

    add_index :users, [:username], unique: true, name: :users_username_key
    add_index :users, [:email], unique: true, name: :users_email_key
  end
end
