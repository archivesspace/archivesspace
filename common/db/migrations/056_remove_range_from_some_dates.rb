require_relative 'utils'

Sequel.migration do

  up do
    
    enum = self[:enumeration].filter(:name => 'date_type').get(:id)
    range = self[:enumeration_value].filter(:value => 'range', :enumeration_id => enum ).get(:id) 
    inclusive = self[:enumeration_value].filter(:value => 'inclusive', :enumeration_id => enum ).get(:id) 

    [ :accession_id, :resource_id, :archival_object_id, :digital_object_id, :digital_object_component_id  ].each do |obj|
      self[:date].filter( :date_type_id => range  ).filter( Sequel.~( obj => nil ) ).update( :date_type_id => inclusive )
    end

  end

end
