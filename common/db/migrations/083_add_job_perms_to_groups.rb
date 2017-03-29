require_relative 'utils'

Sequel.migration do

  up do
    self.transaction do
      create_job_id = self[:permission].where(:permission_code => 'create_job').first[:id]
      cancel_job_id = self[:permission].where(:permission_code => 'cancel_job').first[:id]

      ['repository-advanced-data-entry', 'repository-archivists',
       'repository-managers', 'repository-project-managers'].each do |group_code|

        self[:group].filter(:group_code => group_code).select(:id).each do |group|
          self[:group_permission].insert(:permission_id => create_job_id, :group_id => group[:id])
        end

      end

      self[:group].filter(:group_code => 'repository-project-managers').select(:id).each do |group|
        self[:group_permission].insert(:permission_id => cancel_job_id, :group_id => group[:id])
      end

    end
  end


  down do
    # don't even think about it
  end

end
