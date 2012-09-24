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
    is_admin = groups.any? {|group| group.group_code == Group.ADMIN_GROUP_CODE}

    if is_admin
      return true
    else
      permission = Permission[:permission_code => permission.to_s]

      !permission.nil? && ((self.class.db[:groups].
                            join(:groups_users, :group_id => :id).
                            join(:groups_permissions, :group_id => :group_id).
                            filter(:user_id => self.id,
                                   :permission_id => permission.id,
                                   :repo_id => opts[:repo_id]).
                            count) >= 1)
    end
  end


  many_to_many :groups
end
