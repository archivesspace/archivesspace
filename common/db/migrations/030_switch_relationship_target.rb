# Instead of storing a URI in 'relationship_target', we really want to store a
# record type plus identifier (since the URI contains the repo_id, which can
# change when a record is transferred to a different repository).
#
# That wasn't an issue for agents (since they're global), but could be an issue
# for directional relationships between other record types.

require_relative 'utils'

Sequel.migration do

  up do

    record_type_to_id_map = {}
    # Convert each existing row to the new format
    self[:related_agents_rlshp].each_by_page do |row|
      matches = row[:relationship_target].scan(Regexp.new("/agents/(.*?)/([0-9]+)"))

      if matches.empty?
        raise "Unrecognized value for relationship_target: #{row.inspect}"
      end

      (record_type, id) = matches.first

      record_type_to_id_map[record_type] ||= []
      record_type_to_id_map[record_type] << id.to_i
    end


    # Add the new columns
    alter_table(:related_agents_rlshp) do
      add_column(:relationship_target_record_type, String, :null => true)
      add_column(:relationship_target_id, Integer, :null => true)
    end


    # Convert the existing entries into the new column format
    record_type_to_id_map.each do |record_type, ids|
      ids.each do |id|
        uri = "/agents/#{record_type}/#{id}"
        self[:related_agents_rlshp].filter(:relationship_target => uri).
                                   update(:relationship_target_record_type => record_type,
                                          :relationship_target_id => id)
      end
    end


    # Remove the original column
    alter_table(:related_agents_rlshp) do
      drop_column(:relationship_target)
      set_column_not_null(:relationship_target_record_type)
      set_column_not_null(:relationship_target_id)
    end

  end

end
