require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      update_assessment_record_query = self[:permission].filter(:permission_code => 'update_assessment_record').select(:id)
      if update_assessment_record_query.empty?
        update_assessment_record_id = self[:permission].insert(:permission_code => 'update_assessment_record',
                                                 :description => 'The ability to create and modify assessment records',
                                                 :level => 'repository',
                                                 :created_by => 'admin',
                                                 :last_modified_by => 'admin',
                                                 :create_time => Time.now,
                                                 :system_mtime => Time.now,
                                                 :user_mtime => Time.now)
      else
        update_assessment_record_id = update_assessment_record_query.first[:id]
      end

      delete_assessment_record_query = self[:permission].filter(:permission_code => 'delete_assessment_record').select(:id)
      if delete_assessment_record_query.empty?
        delete_assessment_record_id = self[:permission].insert(:permission_code => 'delete_assessment_record',
                                                               :description => 'The ability to delete assessment records',
                                                               :level => 'repository',
                                                               :created_by => 'admin',
                                                               :last_modified_by => 'admin',
                                                               :create_time => Time.now,
                                                               :system_mtime => Time.now,
                                                               :user_mtime => Time.now)
      else
        delete_assessment_record_id = delete_assessment_record_query.first[:id]
      end

      manage_assessment_attributes_query = self[:permission].filter(:permission_code => 'manage_assessment_attributes').select(:id)
      if manage_assessment_attributes_query.empty?
        manage_assessment_attributes_id = self[:permission].insert(:permission_code => 'manage_assessment_attributes',
                                                               :description => 'The ability to managae assessment attribute definitions',
                                                               :level => 'repository',
                                                               :created_by => 'admin',
                                                               :last_modified_by => 'admin',
                                                               :create_time => Time.now,
                                                               :system_mtime => Time.now,
                                                               :user_mtime => Time.now)
      else
        manage_assessment_attributes_id = manage_assessment_attributes_query.first[:id]
      end

      groups_allowed_to_crud_assessments = [
        'repository-managers',
        'repository-archivists',
        'repository-project-managers',
        'repository-advanced-data-entry',
      ]

      groups_allowed_to_manage_assessment_attributes = [
        'repository-managers',
      ]

      self[:group].filter(:group_code => groups_allowed_to_crud_assessments).select(:id).each do |group|
        self[:group_permission].insert(:permission_id => update_assessment_record_id, :group_id => group[:id])
        self[:group_permission].insert(:permission_id => delete_assessment_record_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => groups_allowed_to_manage_assessment_attributes).select(:id).each do |group|
        self[:group_permission].insert(:permission_id => manage_assessment_attributes_id, :group_id => group[:id])
      end
    end
  end


  down do
  end

end

