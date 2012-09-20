class User < Sequel::Model(:users)
  include ASModel
  plugin :validation_helpers


  def before_save
    self.username = self.username.downcase
  end

  def validate
    validates_unique(:username,
                     :message => "Username '#{self.username}' is already in use")
  end


  # True if a user has access to perform 'permission' in 'repo_id'
  def can?(permission, repo_id)
    permission = Permission[:permission_code => permission]

    !permission.nil? && ((self.class.db[:groups].
                          join(:groups_users, :group_id => :id).
                          join(:groups_permissions, :group_id => :group_id).
                          filter(:user_id => self.id,
                                 :permission_id => permission.id,
                                 :repo_id => repo_id).
                          count) >= 1)
  end


  many_to_many :groups
end
