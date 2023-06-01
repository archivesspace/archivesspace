class User < Sequel::Model(:user)
  include ASModel
  corresponds_to JSONModel(:user)

  many_to_many :group, :join_table => "group_user"

  set_model_scope :global

  @@unlisted_user_ids = nil


  def self.create_from_json(json, opts = {})
    if !opts[:is_hidden_user]
      agent = JSONModel(:agent_person).from_hash(
                {:publish => false,
                :agent_sha1 => SecureRandom.hex,
                :names => [{
                  :primary_name => json.name,
                  :source => 'local',
                  :rules => 'local',
                  :name_order => 'direct',
                  :sort_name_auto_generate => true
              }]}, raise_errors = true, trusted = true)

      CrudHelpers.with_record_conflict_reporting(AgentPerson, agent) do
        agent_obj = AgentPerson.create_from_json(agent, :system_generated => true, :skip_sha => true)

        opts['agent_record_type'] = :agent_person
        opts['agent_record_id'] = agent_obj.id
      end
    end

    obj = super(json, opts)
    make_admin_if_requested(obj, json)
    obj
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.make_admin_if_requested(self, json)
    super
  end


  def self.make_admin_if_requested(obj, json)
    return if !RequestContext.get(:apply_admin_access)

    # Nothing to do if these already agree
    begin
      return if (json.is_admin === obj.can?(:administer_system))
    rescue PermissionNotFound
      # System is being bootstrapped and permissions aren't here yet.  That's
      # fine.
    end

    RequestContext.in_global_repo do
      admins_group = Group.this_repo[:group_code => Group.ADMIN_GROUP_CODE]

      if admins_group
        if json.is_admin
          admins_group.add_user(obj)
        else
          admins_group.remove_user(obj)
        end

        self.broadcast_changes
      end
    end
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      if obj.agent_record_id
        json['agent_record'] = {'ref' => uri_for(obj.agent_record_type, obj.agent_record_id)}
      end

      if obj.can?(:administer_system)
        json['is_admin'] = true
      end
    end
    jsons
  end


  def self.broadcast_changes
    Notifications.notify("REFRESH_ACLS")
  end


  def self.ADMIN_USERNAME
    "admin"
  end


  def self.SEARCH_USERNAME
    AppConfig[:search_username]
  end


  def self.PUBLIC_USERNAME
    AppConfig[:public_username]
  end


  def self.STAFF_USERNAME
    AppConfig[:staff_username]
  end


  def self.unlisted_user_ids
    @@unlisted_user_ids ||= User.filter(:is_hidden_user => 1).collect {|user| user.id}
  end

  def before_save
    super

    self.username = self.username.downcase
  end


  def validate
    validates_unique(:username,
                     :message => "Username '#{self.username}' is already in use")
  end


  def anonymous?
    false
  end


  def derived_permissions
    actual_permissions =
      self.class.db[:group].
           join(:group_user, :group_id => :id).
           join(:group_permission, :group_id => :group_id).
           join(:permission, :id => :permission_id).
           filter(:user_id => self.id).
           select(:permission_code).map {|row| row[:permission_code]}


    actual_permissions.map {|p| Permission.derived_permissions_for(p) }.flatten.uniq
  end


  class PermissionNotFound < StandardError; end


  # True if a user has access to perform 'permission' in 'repo_id'
  def can?(permission_code, opts = {})
    if derived_permissions.include?(permission_code.to_s)
      return true
    end

    permission = Permission[:permission_code => permission_code.to_s]
    global_repo = Repository[:repo_code => Repository.GLOBAL]

    # False if the permission does not exist (or the derived permission is not assigned to this user)
    return false if permission.nil?

    if permission[:level] == "repository" && self.class.active_repository.nil?
      raise("Problem when checking permission: #{permission.permission_code} " +
            "is a repository-level permission, but no repository was set")
    end

    ((self.class.db[:group].
                          join(:group_user, :group_id => :id).
                          join(:group_permission, :group_id => :group_id).
                          filter(:user_id => self.id,
                                 :permission_id => permission.id,
                                 :repo_id => [self.class.active_repository, global_repo.id].reject(&:nil?)).
                          count) >= 1)
  end


  def permissions
    result = {}

    derived = derived_permissions


    # Crikey...
    ds = self.class.db[:group].
      join(:group_user, :group_id => :id).
      join(:group_permission, :group_id => :group_id).
      join(:permission, :id => :permission_id).
      join(:repository, :id => :group__repo_id).
      filter(:user_id => self.id).
      distinct.
      select(Sequel.qualify(:repository, :id).as(:repo_id), Sequel.qualify(:repository, :repo_code).as(:repo_code), :permission_code)

    global_permissions = []

    ds.each do |row|
      repository_uri = JSONModel(:repository).uri_for(row[:repo_id])
      result[repository_uri] ||= derived.clone
      result[repository_uri] << row[:permission_code]

      if row[:repo_code] == Repository.GLOBAL
        global_permissions << row[:permission_code]
      end
    end

    # assume all users can edit themselves for now
    global_permissions << 'edit_user_self'

    # Attach permissions in the global repository under the symbolic name too
    result[Repository.GLOBAL] = global_permissions + derived

    result
  end


  def add_to_groups(groups, delete_all_for_repo_id = false)
    if delete_all_for_repo_id
      groups_ids = self.class.db[:group].where(:repo_id => delete_all_for_repo_id).select(:id)
      self.class.db[:group_user].where(:user_id => self.id, :group_id => groups_ids).delete
    end

    Array(groups).each do |group|
      group.add_user(self)
    end

    self.class.broadcast_changes
  end


  def delete
    raise AccessDeniedException.new("Can't delete system user") if self.is_system_user == 1

    DBAuth.delete_user(self.username)

    # transfer all import jobs to the admin user
    admin_user = User.select(:id).where( :username => "admin" ).first
    Job.filter(:owner_id => self.id).update( :owner_id => admin_user.id )

    Preference.filter(:user_id => self.id).delete
    self.remove_all_group

    super

    if self.agent_record_id
      AgentPerson[self.agent_record_id].delete
    end
  end

end
