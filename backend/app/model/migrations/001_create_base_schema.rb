Sequel.migration do
  up do
    DB_TYPE = self.database_type
    create_table(:sessions) do
      primary_key :id
      String :session_id, :unique => true, :null => false
      DateTime :last_modified, :null => false
      if DB_TYPE == :derby
        Clob :session_data, :null => true
      else
        Blob :session_data, :null => true
      end
    end


    create_table(:auth_db) do
      primary_key :id
      String :username, :unique => true, :null => false
      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
      String :pwhash, :null => false
    end


    create_table(:users) do
      primary_key :id

      String :username, :null => false, :unique => true
      String :first_name, :null => false
      String :last_name, :null => false
      String :auth_source, :null => false
      String :email, :null => true
      String :phone, :null => true
      String :title, :null => true
      String :department, :null => true
      String :contact, :null => true
      String :notes, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups) do
      primary_key :id

      String :group_id, :null => false, :unique => true
      String :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:groups_users) do
      primary_key :id

      Integer :user_id, :null => false
      Integer :group_id, :null => false
    end


    alter_table(:groups_users) do
      add_foreign_key([:user_id], :users, :key => :id)
      add_foreign_key([:group_id], :groups, :key => :id)
    end


    create_table(:repositories) do
      primary_key :id

      String :repo_id, :null => false, :unique => true
      String :description, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end


    create_table(:accessions) do
      primary_key :id

      Integer :repo_id, :null => false

      String :accession_id_0, :null => true
      String :accession_id_1, :null => true
      String :accession_id_2, :null => true
      String :accession_id_3, :null => true

      String :title, :null => true
      String :content_description, :null => true
      String :condition_description, :null => true

      DateTime :accession_date, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:accessions) do
      add_foreign_key([:repo_id], :repositories, :key => :id)

      add_index [:accession_id_0,
                 :accession_id_1,
                 :accession_id_2,
                 :accession_id_3],
      :unique => true,
      :name => "unique_acc_id"
    end


    create_table(:collections) do
      primary_key :id

      Integer :repo_id, :null => false
      String :title, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:collections) do
      add_foreign_key([:repo_id], :repositories, :key => :id)
    end


    create_table(:archival_objects) do
      primary_key :id

      Integer :repo_id, :null => false

      String :id_0, :null => true
      String :id_1, :null => true
      String :id_2, :null => true
      String :id_3, :null => true

      String :title, :null => true

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:archival_objects) do
      add_foreign_key([:repo_id], :repositories, :key => :id)

      add_index [:id_0, :id_1, :id_2, :id_3],
      :unique => true,
      :name => "unique_ao_id"


    end


    create_table(:collection_tree) do
      primary_key :id

      Integer :collection_id, :null => false
      Integer :parent_id, :null => true
      Integer :child_id, :null => false

      DateTime :create_time, :null => false
      DateTime :last_modified, :null => false
    end

    alter_table(:collection_tree) do
      add_foreign_key([:collection_id], :collections, :key => :id)
      add_foreign_key([:parent_id], :archival_objects, :key => :id)
      add_foreign_key([:child_id], :archival_objects, :key => :id)
    end

  end

  down do
    drop_table?(:sessions)
    drop_table?(:auth_db)

    drop_table?(:groups_users)
    drop_table?(:users)
    drop_table?(:groups)

    drop_table?(:accessions)

    drop_table?(:collection_tree)
    drop_table?(:archival_objects)
    drop_table?(:collections)
    drop_table?(:repositories)
  end
end
