require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do

      # remove unused permission
      system_config_id = self[:permission].filter(:permission_code => 'system_config').get(:id)
      if system_config_id
        self[:group_permission].filter(:permission_id => system_config_id).delete
        self[:permission].filter(:permission_code => 'system_config').delete
      end

      # add permission for managing controlled value lists
      manage_enumeration_record_id = self[:permission].filter(:permission_code => 'manage_enumeration_record').get(:id)

      if !manage_enumeration_record_id
        manage_enumeration_record_id = self[:permission].insert(:permission_code => 'manage_enumeration_record',
                                            :description => 'The ability to create, modify and delete a controlled vocabulary list record',
                                            :level => 'repository',
                                            :created_by => 'admin',
                                            :last_modified_by => 'admin',
                                            :create_time => Time.now,
                                            :system_mtime => Time.now,
                                            :user_mtime => Time.now)
      end
    end
  end


  down do
    # don't even think about it
  end

end
