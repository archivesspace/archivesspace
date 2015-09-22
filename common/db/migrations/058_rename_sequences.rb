require_relative 'utils'

Sequel.migration do

  # dedupe and rename existing sequences see:
  # https://archivesspace.atlassian.net/browse/AR-1326

  up do
    puts "Renaming all sequences, this may take a while..."

    self[:sequence].each do |row|
      name = row[:sequence_name]

      # Fix sequence names for children of the root record
      if name.match(/__/)
        self[:sequence].filter(:sequence_name => name).update(:sequence_name => name.sub(/__/, '_'))
      end


      next unless name.match(/\/repositories\/(\d)+\/(resource|digital_object|classification)s\/(\d+)_\/repositories\/\d+\/(archival_object|digital_object_component|classification_term)s\/(\d+)_children_position/)

      repo_id, root_id, record_type, tree_node_id = $1, $3, $4, $5

      all_sequences = self[:sequence].where(Sequel.like(:sequence_name, "%_repositories/#{repo_id}/#{record_type}s/#{tree_node_id}_children_position")).order(:value)

      next unless all_sequences.select(:sequence_name).first[:sequence_name] == name

      sequence_val = if all_sequences.count > 1
                       # reset the sequence value if there are multiple versions
                       self[record_type.intern].filter(:parent_id => tree_node_id).order(:position).select(:position).last[:position]
                     else
                       row[:value]
                     end

      # delete old sequences
      all_sequences.delete

      # update the name and value
      new_name = "/repositories/#{repo_id}/#{record_type}s/#{tree_node_id}_children_position"
      self[:sequence].insert(:sequence_name => new_name, :value => sequence_val)
    end
  end

  down do

  end
end



