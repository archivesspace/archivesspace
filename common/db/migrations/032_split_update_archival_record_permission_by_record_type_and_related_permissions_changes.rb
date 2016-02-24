require_relative 'utils'

Sequel.migration do

  up do
    update_archival_record_permission_id = self[:permission].filter(:permission_code => 'update_archival_record').get(:id)

    if update_archival_record_permission_id
      $stderr.puts("Adding separate permissions for updating major record types")
      update_accession_permission_id = self[:permission].filter(:permission_code => 'update_accession_record').get(:id)
      if update_accession_permission_id.nil?
        $stderr.puts("    ... accession records")
        update_accession_permission_id = self[:permission].insert(:permission_code => 'update_accession_record',
                                                                  :description => 'The ability to create and modify accessions records',
                                                                  :level => 'repository',
                                                                  :created_by => 'admin',
                                                                  :last_modified_by => 'admin',
                                                                  :create_time => Time.now,
                                                                  :system_mtime => Time.now,
                                                                  :user_mtime => Time.now)
      end

      update_resource_permission_id = self[:permission].filter(:permission_code => 'update_resource_record').get(:id)
      if update_resource_permission_id.nil?
        $stderr.puts("    ... resource records")
        update_resource_permission_id = self[:permission].insert(:permission_code => 'update_resource_record',
                                                                 :description => 'The ability to create and modify resource records',
                                                                 :level => 'repository',
                                                                 :created_by => 'admin',
                                                                 :last_modified_by => 'admin',
                                                                 :create_time => Time.now,
                                                                 :system_mtime => Time.now,
                                                                 :user_mtime => Time.now)
      end

      update_digital_object_permission_id = self[:permission].filter(:permission_code => 'update_digital_object_record').get(:id)
      if update_digital_object_permission_id.nil?
        $stderr.puts("    ... digital object records")
        update_digital_object_permission_id = self[:permission].insert(:permission_code => 'update_digital_object_record',
                                                                       :description => 'The ability to create and modify digital object records',
                                                                       :level => 'repository',
                                                                       :created_by => 'admin',
                                                                       :last_modified_by => 'admin',
                                                                       :create_time => Time.now,
                                                                       :system_mtime => Time.now,
                                                                       :user_mtime => Time.now)
      end

      import_permission_id = self[:permission].filter(:permission_code => 'import_records').get(:id)
      if import_permission_id.nil?
        $stderr.puts("    ... running import jobs")
        import_permission_id = self[:permission].insert(:permission_code => 'import_records',
                                                        :description => 'The ability to initiate an importer job',
                                                        :level => 'repository',
                                                        :created_by => 'admin',
                                                        :last_modified_by => 'admin',
                                                        :create_time => Time.now,
                                                        :system_mtime => Time.now,
                                                        :user_mtime => Time.now)
      end

      manage_vocabulary_permission_id = self[:permission].filter(:permission_code => 'manage_vocabulary_record').get(:id)
      if manage_vocabulary_permission_id.nil?
        $stderr.puts("    ... managing vocabulary records")
        manage_vocabulary_permission_id = self[:permission].insert(:permission_code => 'manage_vocabulary_record',
                                                              :description => 'The ability to create, modify and delete an vocabulary record',
                                                              :level => 'repository',
                                                              :created_by => 'admin',
                                                              :last_modified_by => 'admin',
                                                              :create_time => Time.now,
                                                              :system_mtime => Time.now,
                                                              :user_mtime => Time.now)
      end

      update_event_permission_id = self[:permission].filter(:permission_code => 'update_event_record').get(:id)
      if update_event_permission_id.nil?
        $stderr.puts("    ... updating event records")
        update_event_permission_id = self[:permission].insert(:permission_code => 'update_event_record',
                                                              :description => 'The ability to create and modify event records',
                                                              :level => 'repository',
                                                              :created_by => 'admin',
                                                              :last_modified_by => 'admin',
                                                              :create_time => Time.now,
                                                              :system_mtime => Time.now,
                                                              :user_mtime => Time.now)
      end

      $stderr.puts("Updating groups to include the new permssions")
      update_archival_record_group_ids = self[:group_permission].filter(:permission_id => update_archival_record_permission_id).select(:group_id).map {|row| row[:group_id]}.uniq
      update_archival_record_group_ids.each do |group_id|
        self[:group_permission].insert(:permission_id => update_accession_permission_id,
                                       :group_id => group_id)
        self[:group_permission].insert(:permission_id => update_resource_permission_id,
                                       :group_id => group_id)
        self[:group_permission].insert(:permission_id => update_digital_object_permission_id,
                                       :group_id => group_id)
        self[:group_permission].insert(:permission_id => import_permission_id,
                                       :group_id => group_id)
        self[:group_permission].insert(:permission_id => manage_vocabulary_permission_id,
                                       :group_id => group_id)

        if self[:group_permission].filter(:permission_id => update_event_permission_id, :group_id => group_id).get(:id).nil?
          self[:group_permission].insert(:permission_id => update_event_permission_id,
                                         :group_id => group_id)
        end
      end

      $stderr.puts("Deleting update_archival_record permission")
      self[:group_permission].filter(:permission_id => update_archival_record_permission_id).delete
      self[:permission].filter(:id => update_archival_record_permission_id).delete
    end
  end

  down do
    # no going back
  end

end

