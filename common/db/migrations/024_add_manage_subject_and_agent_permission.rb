require_relative 'utils'

Sequel.migration do

  up do
    update_archival_record_permission_id = self[:permission].filter(:permission_code => 'update_archival_record').get(:id)
    delete_archival_record_permission_id = self[:permission].filter(:permission_code => 'delete_archival_record').get(:id)

    if update_archival_record_permission_id && delete_archival_record_permission_id

      manage_agent_permission_id = self[:permission].filter(:permission_code => 'manage_agent_record').get(:id)

      if manage_agent_permission_id.nil?
        manage_agent_permission_id = self[:permission].insert(:permission_code => 'manage_agent_record',
                                                              :description => 'The ability to create, modify and delete an agent record',
                                                              :level => 'repository',
                                                              :created_by => 'admin',
                                                              :last_modified_by => 'admin',
                                                              :create_time => Time.now,
                                                              :system_mtime => Time.now,
                                                              :user_mtime => Time.now)
      end

      manage_subject_permission_id = self[:permission].filter(:permission_code => 'manage_subject_record').get(:id)
      if manage_subject_permission_id.nil?
        manage_subject_permission_id = self[:permission].insert(:permission_code => 'manage_subject_record',
                                                                :description => 'The ability to create, modify and delete a subject record',
                                                                :level => 'repository',
                                                                :created_by => 'admin',
                                                                :last_modified_by => 'admin',
                                                                :create_time => Time.now,
                                                                :system_mtime => Time.now,
                                                                :user_mtime => Time.now)
      end

      update_archival_record_group_ids = self[:group_permission].filter(:permission_id => [delete_archival_record_permission_id, update_archival_record_permission_id]).select(:group_id).map {|row| row[:group_id]}.uniq
      update_archival_record_group_ids.each do |group_id|
        self[:group_permission].insert(:permission_id => manage_agent_permission_id,
                                       :group_id => group_id)
        self[:group_permission].insert(:permission_id => manage_subject_permission_id,
                                       :group_id => group_id)
      end
    end
  end

  down do
  end

end

