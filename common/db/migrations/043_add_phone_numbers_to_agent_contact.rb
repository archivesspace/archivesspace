require_relative 'utils'

Sequel.migration do

  up do

    create_table(:telephone) do
      primary_key :id
      Integer :agent_contact_id
      TextField :number, :null => false
      TextField :ext, :null => true
      apply_mtime_columns
    end

    alter_table(:telephone) do
      add_foreign_key([:agent_contact_id], :agent_contact, :key => :id)
    end

    self[:agent_contact].filter( Sequel.~(:telephone => nil)).or( Sequel.~( :telephone_ext => nil )).each do |row|
      number = row[:telephone]
      ext = row[:telephone_ext]

      if number.nil? && ext
        number = ext
        ext = nil
      end

      self[:telephone].insert( :agent_contact_id => row[:id], :number => number, :ext => ext,
                               :last_modified_by => row[:last_modified_by],
                               :create_time => row[:create_time],
                               :system_mtime => row[:system_mtime],
                               :user_mtime => row[:user_mtime]
                               )
    end

    alter_table(:agent_contact) do
      drop_column(:telephone)
      drop_column(:telephone_ext)
    end

  end

  down do
  end

end
