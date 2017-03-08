require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      create_job_id = self[:permission].insert(:permission_code => 'create_job',
                                               :description => 'The ability to create background jobs',
                                               :level => 'repository',
                                               :created_by => 'admin',
                                               :last_modified_by => 'admin',
                                               :create_time => Time.now,
                                               :system_mtime => Time.now,
                                               :user_mtime => Time.now)

      cancel_job_id = self[:permission].insert(:permission_code => 'cancel_job',
                                               :description => 'The ability to cancel background jobs',
                                               :level => 'repository',
                                               :created_by => 'admin',
                                               :last_modified_by => 'admin',
                                               :create_time => Time.now,
                                               :system_mtime => Time.now,
                                               :user_mtime => Time.now)


      self[:group].filter(:group_code => 'repository-basic-data-entry').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => create_job_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'repository-managers').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => cancel_job_id, :group_id => group[:id])
      end

      self[:group].filter(:group_code => 'administrators').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => create_job_id, :group_id => group[:id])
        self[:group_permission].insert(:permission_id => cancel_job_id, :group_id => group[:id])
      end
    end
  end


  down do
    # don't even think about it
  end

end

