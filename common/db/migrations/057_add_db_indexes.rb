require 'db/migrations/utils'

Sequel.migration do

  up do

    begin
      alter_table(:archival_object) do
        add_index([:parent_id, :root_record_id], :name => "ao_parent_root_idx")
      end
    rescue Sequel::DatabaseError => e
      raise e unless e.to_s =~ /Duplicate key name/
    end

    begin
      alter_table(:sequence) do
        add_index([:sequence_name, :value], :name => "sequence_namevalue_idx")
      end
    rescue Sequel::DatabaseError => e
      raise e unless e.to_s =~ /Duplicate key name/
    end

    begin
      alter_table(:job) do
        add_index([:status], :name => "job_status_idx")
      end
    rescue Sequel::DatabaseError => e
      raise e unless e.to_s =~ /Duplicate key name/
    end

  end

end
