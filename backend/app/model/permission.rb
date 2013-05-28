class Permission < Sequel::Model(:permission)
  include ASModel
  corresponds_to JSONModel(:permission)

  set_model_scope :global

  @derived_permissions = []

  def self.derived?(code)
    @derived_permissions.include?(code)
  end


  def self.define(code, description, opts = {})
    if opts[:derived_permission]
      # Derived permissions aren't actually stored in the database: we just add
      # them to the user's list of permissions at query time.
      @derived_permissions << code
      return
    end

    opts[:level] ||= "repository"

    permission = (Permission[:permission_code => code] or
                  Permission.create(opts.merge(:permission_code => code,
                                               :description => description)))

    # Admin users automatically get everything
    admins = Group.any_repo[:group_code => Group.ADMIN_GROUP_CODE]
    admins.grant(permission.permission_code)
  end

end
