class Permission < Sequel::Model(:permission)
  include ASModel
  corresponds_to JSONModel(:permission)

  set_model_scope :global

  @derived_permissions = []

  def self.derived?(code)
    @derived_permissions.any? {|p| p[:permission_code].casecmp(code) == 0}
  end


  def self.derived_permissions_for(code)
    @derived_permissions.select {|p| p[:implied_by].casecmp(code) == 0}.
                         map {|p| p[:permission_code]}
  end


  def self.define(code, description, opts = {})
    if opts[:implied_by]
      # Derived permissions aren't actually stored in the database: we just add
      # them to the user's list of permissions at query time.
      @derived_permissions << opts.merge(:permission_code => code,
                                         :description => description)

      return
    end

    opts[:level] ||= "repository"

    opts[:system] = (opts[:system] ? 1 : 0)

    permission = (Permission[:permission_code => code] or
                  Permission.create(opts.merge(:permission_code => code,
                                               :description => description)))

    # Admin users automatically get everything
    admins = Group.any_repo[:group_code => Group.ADMIN_GROUP_CODE]
    admins.grant(permission.permission_code)
  end


  # These methods provide a mechanism for plugins to hide (or show)
  # permissions that are not relevant due to customizations made by
  # the plugin. This is done by setting the :system attribute to true.
  # System permissions behave exactly like other permissions except
  # they are hidden from the user.
  # NOTE: the update is done via a direct database query rather than
  #       via the model because the permission table does not have
  #       a :lock_version column, so the optimistic_locking plugin
  #       freaks out on Permission.update
  def self.hide(code)
    DB.open do |db|
      db[:permission].filter(:permission_code => code).update(:system => 1)
    end
  end

  def self.show(code)
    DB.open do |db|
      db[:permission].filter(:permission_code => code).update(:system => 0)
    end
  end
end
