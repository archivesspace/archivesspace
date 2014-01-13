require_relative 'utils'

Sequel.migration do

  up do
    alter_table(:linked_agents_rlshp) do
      HalfLongString :title
    end
  end


  down do
    alter_table(:linked_agents_rlshp) do
      drop_column(:title)
    end
  end

end

