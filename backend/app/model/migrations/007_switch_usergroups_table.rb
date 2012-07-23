Sequel.migration do
  up do
    drop_table(:user_groups)

    create_table(:groups_users) do
      primary_key :id

      Integer :user_id, :null => false
      Integer :group_id, :null => false
    end

    alter_table(:groups_users) do
      add_foreign_key([:user_id], :users, :key => :id)
      add_foreign_key([:group_id], :groups, :key => :id)
    end


  end

  down do

    drop_table(:groups_users)

    create_table(:user_groups) do
      primary_key :id

      String :username, :null => false
      String :group_id, :null => false

      unique [:username, :group_id]
      index :username
      index :group_id
    end

    alter_table(:user_groups) do
      add_foreign_key([:username], :users, :key => :username)
      add_foreign_key([:group_id], :groups, :key => :group_id)
    end
  end
end
