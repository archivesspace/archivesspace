require_relative 'utils'

Sequel.migration do

  up do
  
   enum = self[:enumeration].filter(:name => 'date_type').select(:id)
   date_type = self[:enumeration_value].filter(:value => 'single', :enumeration_id => enum).select(:id) 
   enum = self[:enumeration].filter(:name => 'date_label').select(:id)
   label = self[:enumeration_value].filter(:value => 'other', :enumeration_id => enum ).select(:id) 
   
   date_resource_id = self[:date].where('resource_id IS NOT NULL').select(:resource_id)
   
   no_dates = self[:resource].exclude(:id => date_resource_id).select(:id, :repo_id )
  
   no_dates.update(:system_mtime => Time.now )

   no_dates.each do |resource|
     
     $stderr.puts("Adding 'Date Not Yet Determined' to resource #{resource[:repo_id]}/#{resource[:id] }")
     self[:date].insert( :resource_id => resource[:id] , :label_id => label, :date_type_id => date_type,
                        :expression => "Date Not Yet Determined", :json_schema_version => 1,
                       :create_time => Time.now, :system_mtime => Time.now, :user_mtime => Time.now
                       )
   
   end
     
  end
  
  down do
   self[:date].where(:expression => "Date Not Yet Determined").delete
  end

end

