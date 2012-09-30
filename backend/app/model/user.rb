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
    global_repo = Repository[:repo_code => Group.GLOBAL]

    !permission.nil? && ((self.class.db[:groups].
                          join(:groups_users, :group_id => :id).
                          join(:groups_permissions, :group_id => :group_id).
                          filter(:user_id => self.id,
                                 :permission_id => permission.id,
                                 :repo_id => [opts[:repo_id], global_repo.id].reject(&:nil?)).
                          count) >= 1)
  end


  def permissions
    result = {}

    # Crikey...
    ds = self.class.db[:groups].
      join(:groups_users, :group_id => :id).
      join(:groups_permissions, :group_id => :group_id).
      join(:permissions, :id => :permission_id).
      join(:repositories, :id => :groups__repo_id).
      filter(:user_id => self.id).
      distinct.
      select(:repo_code, :permission_code)

    ds.each do |row|
      result[row[:repo_code]] ||= []
      result[row[:repo_code]] << row[:permission_code]
    end

    result
  end


  many_to_many :groups
end
