require_relative 'utils'

Sequel.migration do

	up do

     
    enum = self[:enumeration].filter(:name => "job_type").get(:id)
  
    if self[:enumeration_value].filter(:value => "report_job", :enumeration_id => enum).count == 0
      count =  self[:enumeration_value].filter(:enumeration_id => enum).order( Sequel.desc(:position)).get(:position)
      self[:enumeration_value].insert(:enumeration_id => enum, :position => count + 1, :value => "report_job", :readonly => 1 )
    end	
    
    add_column :job, :job_params, String 
  
  end

  down do
  end

end
