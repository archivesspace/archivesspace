class User < Sequel::Model(:user)
  include ASModel

  set_model_scope :global
  corresponds_to JSONModel(:user)


  def self.ADMIN_USERNAME
    "admin"
  end


  def self.SEARCH_USERNAME
    AppConfig[:search_username]
  end

  
  def self.unlisted_user_ids
    [2]
  end


  def before_save
    self.username = self.username.downcase
  end


  def validate
    validates_unique(:username,
                     :message => "Username '#{self.username}' is already in use")
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
      select(:repo_code, :permission_code)

    ds.each do |row|
      result[row[:repo_code]] ||= []
      result[row[:repo_code]] << row[:permission_code]
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
