Sequel.migration do

  up do
    alter_table(:repository) do
      add_column(:publish, Integer)
    end

    self[:repository].filter(:hidden => 1).update(:publish => 0)
    self[:repository].filter(:hidden => 0).update(:publish => 1)

    self[:repository].update(:system_mtime => Time.now)
  end


  down do
  end

end

