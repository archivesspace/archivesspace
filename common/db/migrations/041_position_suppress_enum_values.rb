require_relative 'utils'


Sequel.migration do
  up do
    
    auto_increment_opts = self.database_type == :derby ? { :default => 0 } : { :auto_increment => true, :default => 0 }
    
    
    alter_table(:enumeration_value) do
      add_column(:position, :integer, :null => false, :default => 0 )
      add_column(:suppressed, :integer, :default => 0) 
     
      # making enumeration_value a full fledged jsonmodel schema object
      add_column(:lock_version, :integer, :default => 0, :null => false) 
      add_column(:json_schema_version, :integer, :default => 1,  :null => false) 

      # like we created the table with apply_mtime_columns
      add_column(:created_by, String)
      add_column(:last_modified_by, String)
      add_column(:create_time, DateTime)
      add_column(:system_mtime,DateTime)
      add_column(:user_mtime, DateTime)
    end
    
    self[:enumeration_value].order(:value).to_hash_groups(:enumeration_id).each_pair do |enum, rows|
      rows.each_with_index { |row, i| 

        self[:enumeration_value].filter(:value => row[:value], :enumeration_id => row[:enumeration_id]).update(:position => i, 
                                                              :create_time => DateTime.now, :system_mtime => DateTime.now, :user_mtime => DateTime.now  ) }
    end
    
    alter_table(:enumeration_value) do
      add_unique_constraint([:enumeration_id, :position], :name => "enumeration_position_uniq")
    end 
  
  end

  down do

  end

end
