require_relative 'utils'

Sequel.migration do

  up do

      alter_table(:telephone) do
        add_column( :number_type_id, :integer, :null => true)
        add_foreign_key([:number_type_id], :enumeration_value, :key => :id)
      end

      create_editable_enum('telephone_number_type', [ 'business', 'home', 'cell', 'fax' ])
      enum = self[:enumeration].filter(:name => 'telephone_number_type').select(:id).first 
      fax = self[:enumeration_value].filter(:enumeration_id => enum[:id], :value => 'fax' ).select(:id).first

      self[:agent_contact].filter( Sequel.~(:fax => nil) ).each do |row|
        self[:telephone].insert( :agent_contact_id => row[:id], 
                                 :number => row[:fax], 
                                 :number_type_id => fax[:id], 
                                 :last_modified_by => row[:last_modified_by],
                                 :create_time => row[:create_time],
                                 :system_mtime => row[:system_mtime],
                                 :user_mtime => row[:user_mtime]
                               )
      end

      alter_table(:agent_contact) do
        drop_column(:fax)
      end
  end

  down do
  end

end
