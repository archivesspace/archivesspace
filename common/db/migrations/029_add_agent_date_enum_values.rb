require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Adding range date to the list of date_type enums")
    enum = self[:enumeration].filter(:name => 'date_type').select(:id)
    range = self[:enumeration_value].filter(:value => 'range').select(:id) 
    if range.count == 0
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "range", :readonly => 0)
      range = self[:enumeration_value].filter(:value => 'range').select(:id) 
    end

    bulk_date = self[:enumeration_value].filter(:value => "bulk").select(:id)    
    if bulk_date.count == 0
      self[:enumeration_value].insert(:enumeration_id => enum, :value => "bulk", :readonly => 0)
      bulk_date = self[:enumeration_value].filter(:value => "bulk").select(:id)    
    end
    
    dates = self[:date].filter(:date_type_id => bulk_date )
    # if there's not a agent_*_id, then it should not be updated. 
    $stderr.puts("Changing all agent dates that are bulk_dates to ranges ")  
    dates.exclude( Sequel.~( :agent_person_id => nil) &   Sequel.~(:agent_family_id => nil) & Sequel.~( :agent_corporate_entity_id => nil ) & Sequel.~( :agent_software_id => nil)   
                ).update(:date_type_id => range)
  
  end

end
