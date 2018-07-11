require_relative 'utils'

Sequel.migration do

	up do
		enum = self[:enumeration].filter(:name => "job_type").select(:id)
    
    position = self[:enumeration_value].filter( :enumeration_id => enum).order_by(:position).last[:position] + 1
    if self[:enumeration_value].filter(:enumeration_id => enum, :value => "container_conversion_job").count == 0 
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "container_conversion_job", :readonly => 1, :position => position, :suppressed => 1 )
    end	
  end

end
