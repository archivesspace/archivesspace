require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do

      # remove unused permission
      system_config_id = self[:permission].filter(:permission_code => 'system_config').get(:id)
      unless system_config_id.nil?
        self[:group_permission].filter(:permission_id => system_config_id).delete
        self[:permission].filter(:permission_code => 'system_config').delete
      end

      # add permission for managing controlled value lists
      manage_enumeration_record_id = self[:permission].filter(:permission_code => 'manage_enumeration_record').get(:id)

      if manage_enumeration_record_id.nil?
        manage_enumeration_record_id = self[:permission].insert(:permission_code => 'manage_enumeration_record',
                                            :description => 'The ability to create, modify and delete a controlled vocabulary list record',
                                            :level => 'repository',
                                            :created_by => 'admin',
                                            :last_modified_by => 'admin',
                                            :create_time => Time.now,
                                            :system_mtime => Time.now,
                                            :user_mtime => Time.now)
      end

      # default permission to enabled for specified default groups
      self[:group].filter(:group_code => 'repository-advanced-data-entry').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_enumeration_record_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'repository-project-managers').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_enumeration_record_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'repository-archivists').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_enumeration_record_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'repository-managers').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_enumeration_record_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'administrators').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_enumeration_record_id, :group_id => group[:id])
      end
    end
  end


  down do
    # don't even think about it
  end

end
