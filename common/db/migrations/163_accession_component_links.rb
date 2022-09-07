require 'db/migrations/utils'

Sequel.migration do

  up do
    # users of the as_accession_links plugin will already
    # have this table. See https://github.com/hudmol/as_accession_links
    unless tables.include?(:accession_component_links_rlshp)
      create_table(:accession_component_links_rlshp) do
        primary_key :id

        Integer :accession_id
        Integer :archival_object_id

        Integer :suppressed, :default => 0
        Integer :aspace_relationship_position

        apply_mtime_columns(false)
      end

      alter_table(:accession_component_links_rlshp) do
        add_foreign_key([:accession_id], :accession, :key => :id)
        add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      end
    end
  end
end
