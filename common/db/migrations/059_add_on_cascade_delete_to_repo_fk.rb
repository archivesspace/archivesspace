require 'db/migrations/utils'


#
# Currently, there's not any way to delete some types of records, with is a
# PIA when trying to delete repos. Let's delete those on cascade. 
#
Sequel.migration do

  up do

    alter_table(:job) do
      drop_foreign_key([:repo_id])
      drop_foreign_key([:owner_id])
      add_foreign_key([:repo_id], :repository, :key => :id, :on_delete => :cascade, :name => 'job_repo_id_fk' )
      add_foreign_key([:owner_id], :user, :key => :id, :on_delete => :cascade, :name => 'job_owner_id_fk' )
    end

    alter_table(:job_input_file) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id, :on_delete => :cascade, :name => 'job_input_file_job_id_fk')
    end
    
    alter_table(:job_created_record) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id, :on_delete => :cascade, :name => 'job_created_record_job_id_fk')
    end
    
    alter_table(:job_modified_record) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id, :on_delete => :cascade, :name => 'job_modified_record_job_id_fk')
    end

    alter_table(:preference) do
      drop_foreign_key([:repo_id]) 
      drop_foreign_key([:user_id]) 
      add_foreign_key([:repo_id], :repository, :key => :id, :on_delete => :cascade, :name => 'preference_repo_id_fk' )
      add_foreign_key([:user_id], :user, :key => :id, :on_delete => :cascade, :name => 'preference_user_id_fk' )
    end

    alter_table(:group) do
      drop_foreign_key([:repo_id]) 
      add_foreign_key([:repo_id], :repository, :key => :id, :on_delete => :cascade, :name => 'group_repo_id_fk' )
    end

    alter_table(:group_permission) do
       drop_foreign_key([:group_id])
       add_foreign_key([:group_id], :group, :key => :id, :on_delete => :cascade, :name => 'group_permission_group_id_fk' ) 
    end

    alter_table(:group_user) do                                                                                                                                
        drop_foreign_key([:user_id])
        drop_foreign_key([:group_id])
        add_foreign_key([:user_id], :user, :key => :id, :on_delete => :cascade, :name => "group_user_user_id_fk" )                                                                                                          
        add_foreign_key([:group_id], :group, :key => :id, :on_delete => :cascade, :name => 'group_user_group_id_fk')
    end


  end
  
  down do

    alter_table(:job) do
      drop_foreign_key([:repo_id])
      drop_foreign_key([:owner_id])
      add_foreign_key([:repo_id], :repository, :key => :id )
      add_foreign_key([:owner_id], :user, :key => :id )
    end

    alter_table(:job_input_file) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id)
    end
    
    alter_table(:job_created_record) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id)
    end
    
    alter_table(:job_modified_record) do
      drop_foreign_key([:job_id]) 
      add_foreign_key([:job_id], :job, :key => :id)
    end

    alter_table(:preference) do
      drop_foreign_key([:repo_id]) 
      drop_foreign_key([:user_id]) 
      add_foreign_key([:repo_id], :repository, :key => :id )
      add_foreign_key([:user_id], :user, :key => :id )
    end

    alter_table(:group) do
      drop_foreign_key([:repo_id]) 
      add_foreign_key([:repo_id], :repository, :key => :id )
    end

    alter_table(:group_permission) do
       drop_foreign_key([:group_id])
       add_foreign_key([:group_id], :group, :key => :id ) 
    end

    alter_table(:group_user) do                                                                                                                                
        drop_foreign_key([:user_id])
        drop_foreign_key([:group_id])
        add_foreign_key([:user_id], :user, :key => :id )                                                                                                          
        add_foreign_key([:group_id], :group, :key => :id)
    end


  end

end
