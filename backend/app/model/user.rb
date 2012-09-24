class User < Sequel::Model(:users)
  include ASModel
  plugin :validation_helpers


  def self.ADMIN_USERNAME
    "admin"
  end


  def before_save
    self.username = self.username.downcase
  end

  def validate
    validates_unique(:username,
                     :message => "Username '#{self.username}' is already in use")
  end


  # True if a user has access to perform 'permission' in 'repo_id'
  def can?(permission, opts = {})
    permission = Permission[:permission_code => permission.to_s]

    !permission.nil? && ((self.class.db[:groups].
                          join(:groups_users, :group_id => :id).
                          join(:groups_permissions, :group_id => :group_id).
                          filter(:user_id => self.id,
                                 :permission_id => permission.id,
                                 :repo_id => (opts[:repo_id] or Group.GLOBAL)).
                          count) >= 1)
  end


  def permissions(repo_id = Group.GLOBAL)

    self.class.db[:groups].
      join(:groups_users, :group_id => :id).
      join(:groups_permissions, :group_id => :group_id).
      join(:permissions, :id => :permission_id).
      filter(:user_id => self.id,
             :repo_id => repo_id).
      select(:permission_code).
      distinct.
      map {|row| row[:permission_code]}

  end


  many_to_many :groups
end
