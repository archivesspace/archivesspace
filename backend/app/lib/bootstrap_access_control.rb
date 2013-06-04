class ArchivesSpaceService

  def self.set_up_base_permissions

    if not Repository[:repo_code => Group.GLOBAL]
      # Create the "global" repository
      Repository.unrestrict_primary_key
      begin
        Repository.create(:repo_code => Group.GLOBAL,
                          :name => "Global repository",
                          :json_schema_version => JSONModel(:repository).schema_version,
                          :hidden => 1)
      ensure
        Repository.restrict_primary_key
      end
    end

    # Create the Software Agent Record.
    # (should we have a table for storing special DB rows that don't depend on the config?)
    # (should this record be undeletable?)
    if AgentSoftware[1].nil?
      json = JSONModel(:agent_software).from_hash(
                :names => [{
                  :software_name => 'ArchivesSpace',
                  :version => 'alpha',
                  :source => 'local',
                  :rules => 'local',
                  :sort_name_auto_generate => true
              }])
    
      sys_agent = AgentSoftware.create_from_json(json, :system_generated => true)
    else    
  
      Log.warn("Ran access control bootstrap without creating an Agent record for this software.")
    end


    # Create the admin user
    if User[:username => User.ADMIN_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.ADMIN_USERNAME,
                                                       :name => "Administrator"),
                            :source => "local",
                            :is_system_user => 1)
      DBAuth.set_password(User.ADMIN_USERNAME, User.ADMIN_USERNAME)
    end


    global_repo = Repository[:repo_code => Group.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => Group.ADMIN_GROUP_CODE].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => Group.ADMIN_GROUP_CODE,
                                                                           :description => "Administrators"),
                                               :is_system_user => 1)
        created_group.add_user(User[:username => User.ADMIN_USERNAME])
      end
    end


    ## Standard permissions
    Permission.define("system_config",
                      "The ability to manage system configuration options",
                      :level => "global")

    Permission.define("manage_users",
                      "The ability to manage user accounts while logged in",
                      :level => "global")

    Permission.define("view_all_records",
                      "The ability to view any record in the system",
                      :level => "global",
                      :system => true)

    Permission.define("create_repository",
                      "The ability to create new repositories",
                      :level => "global")

    Permission.define("delete_repository",
                      "The ability to delete a repository",
                      :level => "global")

    Permission.define("index_system",
                      "The ability to read any record for indexing",
                      :level => "global",
                      :system => true)

    Permission.define("manage_repository",
                      "The ability to manage a given repository",
                      :level => "repository")

    Permission.define("update_location_record",
                      "The ability to create and modify location records in a given repository",
                      :level => "repository")

    Permission.define("update_archival_record",
                      "The ability to create and modify the major archival record types: accessions/resources/digital objects/components/collection management",
                      :level => "repository")

    Permission.define("update_event_record",
                      "The ability to create and modify event records",
                      :level => "repository")

    Permission.define("delete_event_record",
                      "The ability to delete event records",
                      :level => "repository")

    Permission.define("suppress_archival_record",
                      "The ability to suppress the major archival record types: accessions/resources/digital objects/components/collection management/events",
                      :level => "repository")

    Permission.define("delete_archival_record",
                      "The ability to delete the major archival record types: accessions/resources/digital objects/components/collection management/events",
                      :level => "repository")


    Permission.define("view_suppressed",
                      "The ability to view suppressed records in a given repository",
                      :level => "repository")

    Permission.define("view_repository",
                      "The ability to view a given repository",
                      :level => "repository")

    Permission.define("update_classification_record",
                      "The ability to create and modify classification records",
                      :level => "repository")

    Permission.define("delete_classification_record",
                      "The ability to delete classification records",
                      :level => "repository")

    Permission.define("mediate_edits",
                      "Track concurrent updates to records",
                      :level => "global",
                      :system => true)

    # Updates and deletes to subjects and agents are a bit funny: they're global
    # objects, but users are granted permission to modify them by being
    # associated with a group within a repository.

    Permission.define("update_subject_record",
                      "The ability to create and modify subject records",
                      :derived_permission => true,
                      :level => "repository")

    Permission.define("update_agent_record",
                      "The ability to create and modify agent records",
                      :derived_permission => true,
                      :level => "repository")

    Permission.define("update_vocabulary_record",
                      "The ability to create and modify vocabulary records",
                      :derived_permission => true,
                      :level => "repository")

    Permission.define("delete_agent_record",
                      "The ability to delete agent records",
                      :derived_permission => true,
                      :level => "repository")

    Permission.define("delete_subject_record",
                      "The ability to delete subject records",
                      :derived_permission => true,
                      :level => "repository")

    Permission.define("delete_vocabulary_record",
                      "The ability to delete vocabulary records",
                      :derived_permission => true,
                      :level => "repository")



  end


  def self.create_search_user

    # Create the searchindex user
    if User[:username => User.SEARCH_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.SEARCH_USERNAME,
                                                       :name => "Search Indexer"),
                            :source => "local",
                            :is_system_user => 1)
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
        created_group.grant("view_all_records")
        created_group.grant("index_system")
      end
    end

  end


  def self.create_public_user

    # Create the public_anonymous user
    if User[:username => User.PUBLIC_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.PUBLIC_USERNAME,
                                                       :name => "Public Interface Anonymous"),
                            :source => "local",
                            :is_system_user => 1)
    end

    DBAuth.set_password(User.PUBLIC_USERNAME, AppConfig[:public_user_secret])

    global_repo = Repository[:repo_code => Group.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => Group.PUBLIC_GROUP_CODE].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => Group.PUBLIC_GROUP_CODE,
                                                                           :description => "Public Anonymous"))
        created_group.add_user(User[:username => User.PUBLIC_USERNAME])

        created_group.grant("view_repository")
        created_group.grant("view_all_records")
      end
    end

  end


  # Create the user that the frontend will use for trusted communication with
  # the backend.
  def self.create_staff_user

    if User[:username => User.STAFF_USERNAME].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => User.STAFF_USERNAME,
                                                       :name => "Staff System User"),
                            :source => "local",
                            :is_system_user => 1)
    end

    DBAuth.set_password(User.STAFF_USERNAME, AppConfig[:staff_user_secret])

    global_repo = Repository[:repo_code => Group.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => Group.STAFF_GROUP_CODE].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => Group.STAFF_GROUP_CODE,
                                                                           :description => "Staff System Group"))
        created_group.add_user(User[:username => User.STAFF_USERNAME])

        created_group.grant("mediate_edits")
      end
    end

  end

  set_up_base_permissions
  create_search_user
  create_public_user
  create_staff_user

end
