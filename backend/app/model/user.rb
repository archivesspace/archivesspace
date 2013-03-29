class User < Sequel::Model(:user)
  include ASModel
  corresponds_to JSONModel(:user)

  set_model_scope :global

  @@unlisted_user_ids = nil


  def self.create_from_json(json, opts = {})
    # These users are part of the software
    if json.username == self.SEARCH_USERNAME || json.username == self.PUBLIC_USERNAME

      opts['agent_record_type'] = :agent_software
      opts['agent_record_id'] = 1
    else
      agent = JSONModel(:agent_person).from_hash(
                :names => [{
                  :primary_name => json.name,
                  :source => 'local',
                  :rules => 'local',
                  :name_order => 'direct',
                  :sort_name_auto_generate => true
              }])
      agent_obj = AgentPerson.create_from_json(agent, :system_generated => true)

      opts['agent_record_type'] = :agent_person
      opts['agent_record_id'] = agent_obj.id
    end

    obj = super(json, opts)

    obj
  end

  def sequel_to_jsonmodel(obj, opts = {})
    json = super

    if obj.agent_record_id
      json[agent_record] = {:ref => uri_for(obj.agent_record_type, obj.agent_record_id)}
    end

    json
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


  def self.unlisted_user_ids
    @@unlisted_user_ids if not @@unlisted_user_ids.nil?

    @@unlisted_user_ids = Array(User[:username => [User.SEARCH_USERNAME, User.PUBLIC_USERNAME]]).collect {|user| user.id}

    @@unlisted_user_ids
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


  # True if a user has access to perform 'permission' in 'repo_id'
  def can?(permission_code, opts = {})
    permission = Permission[:permission_code => permission_code.to_s]
    global_repo = Repository[:repo_code => Group.GLOBAL]

    raise "The permission '#{permission_code}' doesn't exist" if permission.nil?

    if permission[:level] == "repository" && self.class.active_repository.nil?
      raise("Problem when checking permission: #{permission.permission_code} " +
            "is a repository-level permission, but no repository was set")
    end

    !permission.nil? && ((self.class.db[:group].
                          join(:group_user, :group_id => :id).
                          join(:group_permission, :group_id => :group_id).
                          filter(:user_id => self.id,
                                 :permission_id => permission.id,
                                 :repo_id => [self.class.active_repository, global_repo.id].reject(&:nil?)).
                          count) >= 1)
  end


  def permissions
    result = {}

    # Crikey...
    ds = self.class.db[:group].
      join(:group_user, :group_id => :id).
      join(:group_permission, :group_id => :group_id).
      join(:permission, :id => :permission_id).
      join(:repository, :id => :group__repo_id).
      filter(:user_id => self.id).
      distinct.
      select(Sequel.qualify(:repository, :id).as(:repo_id), :permission_code)

    ds.each do |row|
      repository_uri = JSONModel(:repository).uri_for(row[:repo_id])
      result[repository_uri] ||= []
      result[repository_uri] << row[:permission_code]
    end

    result
  end


  def add_to_groups(groups)
    Array(groups).each do |group|
      group.add_user(self)
    end
  end


  many_to_many :group, :join_table => "group_user"
end
