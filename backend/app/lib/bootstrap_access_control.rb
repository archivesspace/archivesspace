class ArchivesSpaceService

  def self.create_system_user(username, name, password, hidden = false)
    if User[:username => username].nil?
      User.create_from_json(JSONModel(:user).from_hash(:username => username,
                                                       :name => name),
                            {
                              :source => "local",
                              :is_system_user => 1
                            }.merge(hidden ? {:is_hidden_user => 1} : {}))
      DBAuth.set_password(username, password)

      return true
    end

    false
  end


  def self.create_hidden_system_user(username, name, password)
    self.create_system_user(username, name, password, true)
  end


  def self.create_group(group_code, description, users_to_add, permissions)
    global_repo = Repository[:repo_code => Repository.GLOBAL]

    RequestContext.open(:repo_id => global_repo.id) do
      if Group[:group_code => group_code].nil?
        created_group = Group.create_from_json(JSONModel(:group).from_hash(:group_code => group_code,
                                                                           :description => description),
                                               :is_system_user => 1)
        users_to_add.each do |user|
          created_group.add_user(User[:username => user])
        end

        permissions.each do |permission|
          created_group.grant(permission)
        end

        return true
      end
    end

    false
  end


  def self.set_up_base_permissions

    if not Repository[:repo_code => Repository.GLOBAL]
      Repository.create(:repo_code => Repository.GLOBAL,
                        :name => "Global repository",
                        :json_schema_version => JSONModel(:repository).schema_version,
                        :hidden => 1)
    end

    AgentSoftware.ensure_correctly_versioned_archivesspace_record


    # Create the admin user
    self.create_system_user(User.ADMIN_USERNAME, "Administrator", AppConfig[:default_admin_password])
    self.create_group(Group.ADMIN_GROUP_CODE, "Administrators", [User.ADMIN_USERNAME], [])


    ## Standard permissions
    Permission.define("administer_system",
                      "The ability to act as a system administrator",
                      :level => "global")

    Permission.define("manage_users",
                      "The ability to manage user accounts while logged in",
                      :level => "global")

    Permission.define("become_user",
                      "The ability to masquerade as another user",
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

    Permission.define("transfer_repository",
                      "The ability to transfer the contents of a repository",
                      :level => "repository")

    Permission.define("index_system",
                      "The ability to read any record for indexing",
                      :level => "global",
                      :system => true)

    Permission.define("manage_repository",
                      "The ability to manage a given repository",
                      :level => "repository")

    Permission.define("update_accession_record",
                      "The ability to create and modify accessions records",
                      :level => "repository")

    Permission.define("update_resource_record",
                      "The ability to create and modify resources records",
                      :level => "repository")

    Permission.define("update_digital_object_record",
                      "The ability to create and modify digital objects records",
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

    Permission.define("transfer_archival_record",
                      "The ability to transfer records between different repositories",
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

    Permission.define("import_records",
                      "The ability to initiate an importer job",
                      :level => "repository")

    Permission.define("cancel_importer_job",
                      "The ability to cancel a queued or running importer job",
                      :level => "repository")

    Permission.define("create_job",
                      "The ability to create background jobs",
                      :level => "repository")

    Permission.define("cancel_job",
                      "The ability to cancel background jobs",
                      :level => "repository")


    # Updates and deletes to locations, subjects, agents, and enumerations are a bit funny: they're
    # global objects, but users are granted permission to modify them by being
    # associated with a group within a repository.
    Permission.define("manage_subject_record",
                      "The ability to create, modify and delete a subject record",
                      :level => "repository")

    Permission.define("update_subject_record",
                      "The ability to create and modify subject records",
                      :implied_by => 'manage_subject_record',
                      :level => "global")

    Permission.define("manage_agent_record",
                      "The ability to create, modify and delete an agent record",
                      :level => "repository")

    Permission.define("update_agent_record",
                      "The ability to create and modify agent records",
                      :implied_by => 'manage_agent_record',
                      :level => "global")

    Permission.define("manage_vocabulary_record",
                      "The ability to create, modify and delete a vocabulary record",
                      :level => "repository")

    Permission.define("update_vocabulary_record",
                      "The ability to create and modify vocabulary records",
                      :implied_by => 'manage_vocabulary_record',
                      :level => "global")

    Permission.define("update_location_record",
                      "The ability to create and modify location records",
                      :implied_by => 'manage_repository',
                      :level => "global")

    Permission.define("delete_agent_record",
                      "The ability to delete agent records",
                      :implied_by => 'manage_agent_record',
                      :level => "global")

    Permission.define("delete_subject_record",
                      "The ability to delete subject records",
                      :implied_by => 'manage_subject_record',
                      :level => "global")

    Permission.define("delete_vocabulary_record",
                      "The ability to delete vocabulary records",
                      :implied_by => 'delete_archival_record',
                      :level => "global")

    Permission.define("manage_enumeration_record",
                      "The ability to create, modify and delete a controlled vocabulary list record",
                      :level => "repository")

    Permission.define("update_enumeration_record",
                      "The ability to manage controlled vocabulary lists",
                      :implied_by => 'manage_enumeration_record',
                      :level => "global")


    # Merge permissions are special too.  A user with merge_agents_and_subjects
    # in any repository is granted merge_agent_record and merge_subject_record
    Permission.define("merge_agents_and_subjects",
                      "The ability to merge agent/subject records",
                      :level => "repository")


    Permission.define("merge_subject_record",
                      "The ability to merge subject records",
                      :implied_by => 'merge_agents_and_subjects',
                      :level => "global")

    Permission.define("merge_agent_record",
                      "The ability to merge agent records",
                      :implied_by => 'merge_agents_and_subjects',
                      :level => "global")

    Permission.define("merge_archival_record",
                      "The ability to merge archival records records",
                      :level => "repository")


    Permission.define("manage_rde_templates",
                      "The ability to create and delete RDE templates",
                      :level => "repository")

    Permission.define("update_container_record",
                  "The ability to create and update container records",
                  :level => "repository")

    Permission.define("manage_container_record",
                  "The ability to delete and bulk update container records",
                  :level => "repository")

    Permission.define("manage_container_profile_record",
                  "The ability to create, modify and delete a container profile record",
                  :level => "repository")

    Permission.define("update_container_profile_record",
                  "The ability to create/update/delete container profile records",
                  :implied_by => 'manage_container_profile_record',
                  :level => "global")

    Permission.define("manage_location_profile_record",
                      "The ability to create, modify and delete a location profile record",
                      :level => "repository")

    Permission.define("update_location_profile_record",
                      "The ability to create/update/delete location profile records",
                      :implied_by => 'manage_location_profile_record',
                      :level => "global")

    Permission.define("update_assessment_record",
                      "The ability to create and modify assessment records",
                      :level => "repository")

    Permission.define("delete_assessment_record",
                      "The ability to delete assessment records",
                      :level => "repository")

    Permission.define("manage_assessment_attributes",
                      "The ability to managae assessment attribute definitions",
                      :level => "repository")
  end


  def self.create_search_user
    self.create_hidden_system_user(User.SEARCH_USERNAME, "Search Indexer", AppConfig[:search_user_secret])
    DBAuth.set_password(User.SEARCH_USERNAME, AppConfig[:search_user_secret])
    self.create_group(Group.SEARCHINDEX_GROUP_CODE, "Search index", [User.SEARCH_USERNAME],
                      ["view_repository", "view_suppressed", "view_all_records", "index_system"])
  end


  def self.create_public_user
    self.create_hidden_system_user(User.PUBLIC_USERNAME, "Public Interface Anonymous", AppConfig[:search_user_secret])
    DBAuth.set_password(User.PUBLIC_USERNAME, AppConfig[:public_user_secret])
    self.create_group(Group.PUBLIC_GROUP_CODE, "Public Anonymous", [User.PUBLIC_USERNAME],
                      ["view_repository", "view_all_records"])
  end


  def self.create_staff_user
    self.create_hidden_system_user(User.STAFF_USERNAME, "Staff System User", AppConfig[:search_user_secret])
    DBAuth.set_password(User.STAFF_USERNAME, AppConfig[:staff_user_secret])
    self.create_group(Group.STAFF_GROUP_CODE, "Staff System Group", [User.STAFF_USERNAME],
                      ["mediate_edits"])
  end


  set_up_base_permissions
  create_search_user
  create_public_user
  create_staff_user

end
