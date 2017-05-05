Sequel.migration do

  up do
    drop_table(:housed_at_rlshp)
    drop_table(:container)
  end


  down do
    # no going back
  end

end

