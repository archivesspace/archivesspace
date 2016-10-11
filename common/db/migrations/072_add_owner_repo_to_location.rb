require_relative 'utils'

Sequel.migration do

  up do

    create_table(:owner_repo_rlshp) do
      primary_key :id

      Integer :location_id
      Integer :repository_id
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:owner_repo_rlshp) do
      add_foreign_key([:location_id], :location, :key => :id)
      add_foreign_key([:repository_id], :repository, :key => :id)
    end

  end

end
