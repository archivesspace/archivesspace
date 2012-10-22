class Group < Sequel::Model(:groups)
  plugin :validation_helpers
  include ASModel

  many_to_many :users
  many_to_many :permissions


  def self.GLOBAL
    # The repository code indicating that this group is global to all repositories
    '_archivesspace'
  end

  def self.ADMIN_GROUP_CODE
    'administrators'
  end


  def self.set_members(obj, json)
    obj.remove_all_users
    (json.member_usernames or []).map {|username|
      user = User[:username => username]
      obj.add_user(user) if user
    }
  end


  def self.set_permissions(obj, json)
    obj.remove_all_permissions
    (json.grants_permissions or []).each do |permission_code|
      permission = Permission[:permission_code => permission_code]

      if permission.nil?
        raise "Unknown permission code: #{permission_code}"
      end

      if permission[:level] == 'global'
        raise AccessDeniedException.new("You can't assign a global permission to a repository")
      end

      obj.add_permission(permission)
    end
  end


  def self.create_from_json(json, opts = {})
    obj = super
    set_members(obj, json)
    set_permissions(obj, json)

    broadcast_changes
    obj
  end


  def update_from_json(json, opts = {})
    super
    self.class.set_members(self, json) if opts[:with_members]
    self.class.set_permissions(self, json)

    self.class.broadcast_changes
    self.id
  end


  def grant(permission_code)
    permission = Permission[:permission_code => permission_code.to_s]

    if self.class.db[:groups_permissions].filter(:group_id => self.id,
                                                 :permission_id => permission.id).empty?
      add_permission(permission)
    end
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    if opts[:with_members]
      json.member_usernames = obj.users.map {|user| user[:username]}
    end

    json.grants_permissions = obj.permissions.map {|permission| permission[:permission_code]}

    json
  end


  def validate
    super
    validates_unique([:repo_id, :group_code],
                     :message => "Group code must be unique within a repository")
    map_validation_to_json_property([:repo_id, :group_code], :group_code)
  end


  def self.broadcast_changes
    Webhooks.notify("REFRESH_ACLS")
  end
end
