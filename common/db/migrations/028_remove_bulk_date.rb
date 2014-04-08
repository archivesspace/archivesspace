require_relative 'utils'

Sequel.migration do

  up do
    
    bulk_dates = self[:enumeration_value].filter(:value => "bulk").select(:id)
    inclusive_dates = self[:enumeration_value].filter(:value => "inclusive" ).select(:id)
    self[:date].filter(:date_type_id => bulk_dates ).update(:date_type_id => inclusive_dates)
    self[:enumeration_value].filter(:id => bulk_dates).delete 
  end


  down do
    # No going back!
  end

end
