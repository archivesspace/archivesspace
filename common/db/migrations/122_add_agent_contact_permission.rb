require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do

      # add permission for viewing agent contact details
      view_agent_contact_record = self[:permission].filter(:permission_code => 'view_agent_contact_record').get(:id)

      if !view_agent_contact_record
        view_agent_contact_record = self[:permission].insert(:permission_code => 'view_agent_contact_record',
                                            :description => 'The ability to view contact details for agent records',
                                            :level => 'repository',
                                            :created_by => 'admin',
                                            :last_modified_by => 'admin',
                                            :create_time => Time.now,
                                            :system_mtime => Time.now,
                                            :user_mtime => Time.now)
      end

      # grant new permission to appropriate groups
      if view_agent_contact_record
        ["repository-managers", "repository-archivists", "repository-project-managers"].each do |grp|
          groups_that_can = self[:group].filter(:group_code => grp).get(:id)
          if groups_that_can
            self[:group_permission].insert(:permission_id => view_agent_contact_record, :group_id => groups_that_can)
          end
        end
      end

    end
  end


  down do
    # don't even think about it
  end

end
