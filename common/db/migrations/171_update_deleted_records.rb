require_relative 'utils'

Sequel.migration do

  up do

    record_type_map = {
      'resources' => :resource,
      'archival_objects' => :archival_object,
      'accessions' => :accession,
      'digital_objects' => :digital_object,
      'digital_object_components' => :digital_object_component,
      'top_containers' => :top_container,
      'events' => :event,
      'assessments' => :assessment,
      'classifications' => :classification,
      'classification_terms' => :classification_term,
    }

    uri_regex = Regexp.compile(/^\/repositories\/(\d+)\/(.+)\/(\d+)$/)

    # Remove rows in deleted_records for records that have been transferred back to their previous repositories
    rows_deleted = 0
    self[:deleted_records].all.each do |row|
      (repo_id, record_type, record_id) = row[:uri].scan(uri_regex).first
      unless record_type.nil?
        table_name = record_type_map[record_type]
        unless table_name.nil?
          if self[table_name].filter(:repo_id => repo_id).filter(:id => record_id).select(:id).count > 0
            self[:deleted_records].filter(:id => row[:id]).delete
            rows_deleted += 1
          end
        end
      end
    end
    $stderr.puts("Deleted #{rows_deleted} rows from deleted_records table") if rows_deleted > 0

    # Add index on the uri column to speed up transfers of records between repositories
    alter_table(:deleted_records) do
      add_index(:uri)
    end

  end

  down do

    alter_table(:deleted_records) do
      drop_index(:uri)
    end

  end

end
