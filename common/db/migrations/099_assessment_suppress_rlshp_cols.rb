require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:assessment_rlshp) do
      add_column(:suppressed, Integer, :default => 0, :null => false)
    end
    alter_table(:surveyed_by_rlshp) do
      add_column(:suppressed, Integer, :default => 0, :null => false)
    end
    alter_table(:assessment_reviewer_rlshp) do
      add_column(:suppressed, Integer, :default => 0, :null => false)
    end
  end


  down do
  end

end

