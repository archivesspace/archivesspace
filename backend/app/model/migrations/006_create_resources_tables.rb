Sequel.migration do
  up do
    create_table(:resources) do
      primary_key :id

      String :repo_id, :null => false

      String :resource_id, :null => false, :unique => true
      String :title, :null => false
      String :level, :null => false
      String :language, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:resources) do
      add_foreign_key([:repo_id], :repositories, :key => :repo_id)
    end

  end

  down do
    drop_table(:resources)
  end
end
