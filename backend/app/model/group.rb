class Group < Sequel::Model(:groups)
  plugin :validation_helpers
  include ASModel

  many_to_many :users
  many_to_many :permissions


  def self.set_members(obj, json)
    obj.remove_all_users
    (json.member_usernames or []).map {|username|
      user = User[:username => username]
      obj.add_user(user) if user
    }
  end


  def self.set_permissions(obj, json)
    obj.remove_all_permissions
    (json.grants_permissions or []).map {|permission| obj.add_permission(Permission[:permission_code => permission])}
  end


  def self.create_from_json(json, opts = {})
    obj = super(json, opts)
    set_members(obj, json) if opts[:with_members]
    set_permissions(obj, json)

    obj
  end


  def update_from_json(json, opts = {})
    super
    self.class.set_members(self, json) if opts[:with_members]
    self.class.set_permissions(self, json)

    self.id
  end


  def self.sequel_to_jsonmodel(obj, type, opts = {})
    json = super

    if opts[:with_members]
      json.member_usernames = obj.users.map {|user| user[:username]}
    end

    json
  end


  def validate
    super
    validates_unique([:repo_id, :group_code],
                     :message => "Group code must be unique within a repository")
  end

end
