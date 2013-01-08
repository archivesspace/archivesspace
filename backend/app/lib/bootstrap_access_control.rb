class ArchivesSpaceService

  def self.set_up_base_permissions

    if not Repository[:repo_code => Group.GLOBAL]
      # Create the "global" repository
      Repository.unrestrict_primary_key
      begin
        Repository.create(:repo_code => Group.GLOBAL,
                          :description => "Global repository",
                          :hidden => 1)
      ensure
        Repository.restrict_primary_key
      end
    end


    # Create the admin user
    if User[:username => User.ADMIN_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.ADMIN_USERNAME,
                                                       :name => "Administrator"),
                            :source => "local")
      DBAuth.set_password(User.ADMIN_USERNAME, User.ADMIN_USERNAME)
    end


    global_repo = Repository[:repo_code => Group.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => Group.ADMIN_GROUP_CODE].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => Group.ADMIN_GROUP_CODE,
                                                                           :description => "Administrators"))
        created_group.add_user(User[:username => User.ADMIN_USERNAME])
      end
    end


    ## Standard permissions
    Permission.define("manage_users",
                      "The ability to manage user accounts while logged in",
                      :level => "global")

    Permission.define("view_all_records",
                      "The ability to view any record in the system",
                      :level => "global")

    Permission.define("create_repository",
                      "The ability to create new repositories",
                      :level => "global")

    Permission.define("index_system",
                      "The ability to read any record for indexing",
                      :level => "global")

    Permission.define("manage_repository",
                      "The ability to manage a given repository",
                      :level => "repository")

    Permission.define("update_repository",
                      "The ability to create and modify records in a given repository",
                      :level => "repository")

    Permission.define("view_suppressed",
                      "The ability to view suppressed records in a given repository",
                      :level => "repository")

    Permission.define("view_repository",
                      "The ability to view a given repository",
                      :level => "repository")
  end


  def self.create_search_user

    # Create the searchindex user
    if User[:username => User.SEARCH_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.SEARCH_USERNAME,
                                                       :name => "Search Indexer"),
                            :source => "local")
    end

    DBAuth.set_password(User.SEARCH_USERNAME, AppConfig[:search_user_secret])

    global_repo = Repository[:repo_code => Group.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => Group.SEARCHINDEX_GROUP_CODE].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => Group.SEARCHINDEX_GROUP_CODE,
                                                                           :description => "Search index"))
        created_group.add_user(User[:username => User.SEARCH_USERNAME])

        created_group.grant("view_repository")
        created_group.grant("view_suppressed")
        created_group.grant("index_system")
      end
    end

  end


  set_up_base_permissions
  create_search_user
end
