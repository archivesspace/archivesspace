require_relative 'utils'

Sequel.migration do

  up do

      create_table(:revision_statement) do
        primary_key :id
        Integer :resource_id 
        String :date
        TextField :description
        apply_mtime_columns
      end

      alter_table(:revision_statement) do
        add_foreign_key([:resource_id], :resource, :key => :id)
      end
    
      self[:resource].filter( Sequel.~(:finding_aid_revision_date => nil)).or( Sequel.~( :finding_aid_revision_description => nil )).each do |row|
         
        date = row[:finding_aid_revision_date] ? row[:finding_aid_revision_date] : 'finding aid revision date not supplied' 
        desc = row[:finding_aid_revision_description] ? row[:finding_aid_revision_description] : 'finding aid revisiion description not supplied'
        
        self[:revision_statement].insert( 
                                  :resource_id => row[:id],
                                  :date => date, 
                                  :description => desc,
                                  :last_modified_by => row[:last_modified_by],
                                  :create_time => row[:create_time],
                                  :system_mtime => row[:system_mtime],
                                  :user_mtime => row[:user_mtime])
      end
      
      alter_table(:resource) do
        drop_column(:finding_aid_revision_date)
        drop_column(:finding_aid_revision_description)
      end

  end

  down do
  end

end
