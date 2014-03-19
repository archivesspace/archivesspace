class Group < Sequel::Model(:group)
  include ASModel
  corresponds_to JSONModel(:group)


  set_model_scope :repository

  many_to_many :user, :join_table => :group_user
  many_to_many :permission, :join_table => :group_permission


  def self.ADMIN_GROUP_CODE
    'administrators'
  end


  def self.SEARCHINDEX_GROUP_CODE
    'searchindex'
  end


  def self.PUBLIC_GROUP_CODE
    'publicanonymous'
  end

  def self.STAFF_GROUP_CODE
    'staffsystem'
  end


  def before_save
    super

    self.group_code_norm = self.group_code.downcase
  end


  def self.set_members(obj, json)
    nonusers = []
    (json.member_usernames or []).map {|username|
      user = User[:username => username]
      if not user
        nonusers << username
      end
    }

    if nonusers.length > 0
      if nonusers.length == 1
        raise UserNotFoundException.new("User #{nonusers[0]} does not exist")
      else
        raise UserNotFoundException.new("Users #{nonusers.join(', ')} do not exist")
      end
    end

    obj.remove_all_user
    (json.member_usernames or []).map {|username|
      user = User[:username => username]
      obj.add_user(user) if user
    }
  end


  def self.set_permissions(obj, json)
    obj.remove_all_permission
    (json.grants_permissions or []).each do |permission_code|

      next if Permission.derived?(permission_code)

      permission = Permission[:permission_code => permission_code]

      if permission.nil?
        raise "Unknown permission code: #{permission_code}"
      end

      if permission[:level] == 'global'
        Log.error("You can't assign a global permission to a repository")
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


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super
    self.class.set_members(self, json) if opts[:with_members]
    self.class.set_permissions(self, json)

    self.class.broadcast_changes
    self.id
  end


  def grant(permission_code)
    permission = Permission[:permission_code => permission_code.to_s]

    if self.class.db[:group_permission].filter(:group_id => self.id,
                                               :permission_id => permission.id).empty?
      add_permission(permission)
    end
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      if opts[:with_members]
        json.member_usernames = obj.user.map {|user| user[:username]}
      end

      json.grants_permissions = obj.permission.map {|permission| permission[:permission_code]}
    end

    jsons
  end


  def validate
    super
    self.group_code_norm = self.group_code.downcase
    validates_unique([:repo_id, :group_code_norm],
                     :message => "Group code must be unique within a repository")
    map_validation_to_json_property([:repo_id, :group_code_norm], :group_code)
  end


  def self.broadcast_changes
    Notifications.notify("REFRESH_ACLS")
  end


  def delete
    remove_all_permission
    remove_all_user

    super
    self.class.broadcast_changes
  end


  def self.transfer_all(source_repository, target_repository)
    # Groups aren't candidates for being transferred, so we don't call super.
  end

end
