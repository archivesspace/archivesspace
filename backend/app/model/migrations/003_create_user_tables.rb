Sequel.migration do
  up do
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


    DB.connect
    puts "Creating default admin account (username: 'admin'; password: 'admin123')"
    user_manager = UserManager.new
    DB.open do |db|
      user_manager.create_user("admin", "Admin", "User", "local")
      user_manager.create_group("admins", "Administrators")
      user_manager.assign_user_to_group("admin", "admins")

      db_auth = DBAuth.new
      db_auth.set_password("admin", "admin123")
    end

  end

  down do
    drop_table(:users)
    drop_table(:groups)
    drop_table(:user_groups)
  end
end
