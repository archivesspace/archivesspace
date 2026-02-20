require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      # add permission for viewing pui
      view_pui_permission = self[:permission].filter(:permission_code => 'view_pui').get(:id)

      if !view_pui_permission
        view_pui_permission = self[:permission].insert(:permission_code => 'view_pui',
                                            :description => 'The ability to view the PUI',
                                            :level => 'repository',
                                            :created_by => 'admin',
                                            :last_modified_by => 'admin',
                                            :create_time => Time.now,
                                            :system_mtime => Time.now,
                                            :user_mtime => Time.now)
      end

      # grant new permission to new group
      if view_pui_permission
        self[:group].all.each do |grp|
          self[:group_permission].insert(:permission_id => view_pui_permission, :group_id => grp[:id])
        end
      end

    end
  end


  down do
    # don't even think about it
  end

end
