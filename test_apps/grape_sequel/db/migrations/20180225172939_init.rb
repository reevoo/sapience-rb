Sequel.migration do
  up do
    create_table :posts do
      primary_key :id
      String :title
      String :body
    end
  end

  down do
    drop_table :posts
  end
end
