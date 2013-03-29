class Permission < Sequel::Model(:permission)
  include ASModel
  corresponds_to JSONModel(:permission)

  set_model_scope :global


  def self.define(code, description, opts = {})
    opts[:level] ||= "repository"

    permission = (Permission[:permission_code => code] or
                  Permission.create(opts.merge(:permission_code => code,
                                               :description => description)))

    # Admin users automatically get everything
    admins = Group.any_repo[:group_code => Group.ADMIN_GROUP_CODE]
    admins.grant(permission.permission_code)
  end

end
