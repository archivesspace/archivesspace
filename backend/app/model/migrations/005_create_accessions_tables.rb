Sequel.migration do
  up do
    create_table(:accessions) do
      primary_key :id

      String :repo_id, :null => false

      String :accession_id, :null => false, :unique => true
      String :title, :null => false
      String :content_description, :null => false
      String :condition_description, :null => false

      DateTime :accession_date, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:accessions) do
      add_foreign_key([:repo_id], :repositories, :key => :repo_id)
    end

  end

  down do
    drop_table(:accessions)
  end
end
