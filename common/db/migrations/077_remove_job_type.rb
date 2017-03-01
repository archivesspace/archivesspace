#require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:job) do
      drop_foreign_key(:job_type_id)
    end

    enum = self[:enumeration].filter(:name => 'job_type').first
    self[:enumeration_value].filter(:enumeration_id => enum[:id]).delete
    self[:enumeration].filter(:name => 'job_type').delete
  end


  down do
    # no going back
  end

end

