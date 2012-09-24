class Permission < Sequel::Model(:permissions)
  include ASModel
  plugin :validation_helpers

  def self.define(opts)
    permission = (Permission[:permission_code => opts[:permission_code]] or Permission.create(opts))

    # Admin users automatically get everything
    admins = Group[:group_code => Group.ADMIN_GROUP_CODE]
    admins.grant(permission.permission_code)
  end

end
