require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      $stderr.puts("Adding view_pui permission")
      view_pui_permission = self[:permission].filter(permission_code: 'view_pui').get(:id)

      if !view_pui_permission
        view_pui_permission = self[:permission].insert(permission_code: 'view_pui',
                                                       description: 'The ability to view the PUI',
                                                       level: 'global',
                                                       create_time: Time.now,
                                                       system_mtime: Time.now,
                                                       user_mtime: Time.now)
      end

      # grant new permission to group if it exists (it probably doesn't)
      pui_viewer_group = self[:group].filter(group_code: 'pui-viewers').get(:id)
      if view_pui_permission && pui_viewer_group
        self[:group_permission].insert(permission_id: view_pui_permission, group_id: pui_viewer_group[:id])
      end

    end
  end


  down do
    # don't even think about it
  end

end
