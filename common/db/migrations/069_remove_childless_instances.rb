require_relative 'utils'

Sequel.migration do

  # sometimes is snows in April. Sometimes instances lose their containers.
  # This is rare but we should remove them here, since this might cause prob
  # with TC conversion..
	up do
    # we exclude DO instances
		enum = self[:enumeration].filter(:name => "instance_instance_type").get(:id)
    enum_val = self[:enumeration_value].filter( :enumeration_id => enum, :value => "digital_object").get(:id)
    
    # cant remember how to delete with sequel on a join... 
    instances = self[:instance].left_join(:container, { :instance__id => :container__instance_id })
                  .left_join(:sub_container, { :instance__id => :sub_container__instance_id })
                  .where(:container__instance_id => nil, :sub_container__instance_id => nil)
                  .exclude(:instance__instance_type_id => enum_val ).select(:instance__id)
                  .map { |v| v[:id] } 
                  
    self[:instance].where(:id => instances).delete 
  end

end
