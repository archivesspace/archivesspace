Sequel.migration do

  up do
    alter_table(:job) do
      add_column(:job_type, String, :null => false, :default => 'unknown_job_type')
    end

    self[:job].update(:job_type => self[:enumeration_value].filter(:id => :job_type_id).select(:value))

    alter_table(:job) do
      drop_foreign_key(:job_type_id)
    end

    self.transaction do
      enum = self[:enumeration].filter(:name => 'job_type').first
      self[:enumeration_value].filter(:enumeration_id => enum[:id]).delete
      self[:enumeration].filter(:name => 'job_type').delete
    end
  end


  down do
    # no going back
  end

end

