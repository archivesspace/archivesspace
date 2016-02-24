require_relative 'utils'

Sequel.migration do

	up do
		enum = self[:enumeration].filter(:name => "job_type").get(:id)
    count = ( self[:enumeration_value].filter(:enumeration_id => enum).count )
    
    self[:enumeration_value].insert(:enumeration_id => enum, :position => count, :value => "report_job", :readonly => 1 )
	
    add_column :job, :job_params, String 
  end

  down do
  end

end
