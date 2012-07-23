Sequel.migration do
  up do
    create_table(:repositories) do
      primary_key :id

      String :repo_id, :null => false, :unique => true
      String :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end
  end

  down do
    drop_table(:repositories)
  end
end
