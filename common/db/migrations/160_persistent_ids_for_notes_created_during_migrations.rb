require 'json'

Sequel.migration do
  $stderr.puts "Assigning note persistent ids for agent contact notes"
  up do
    suspect_fks = [
      :rights_statement_id,
      :lang_material_id,
      :agent_topic_id,
      :agent_place_id,
      :agent_occupation_id,
      :agent_function_id,
      :agent_gender_id,
      :used_language_id,
      :agent_contact_id
    ]

    self[:note]
      .left_join(:note_persistent_id, Sequel.qualify(:note, :id) => Sequel.qualify(:note_persistent_id, :note_id))
      .filter(Sequel.qualify(:note_persistent_id, :note_id) => nil)
      .select(Sequel.qualify(:note, :id), :notes, *suspect_fks)
      .each do |row|
      notes = JSON.parse(row[:notes].to_s)
      next unless notes["persistent_id"]
      row.reject! { |k, v| v.nil? }
      next unless row.keys.last.to_s =~ /_id$/
      parent_type = row.keys.last.to_s.sub(/_id$/, '')
      parent_id = row.values.last
      self[:note_persistent_id].insert(note_id: row[:id], persistent_id: notes["persistent_id"], parent_type: parent_type, parent_id: parent_id)
    end
  end
end
