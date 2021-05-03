require 'time'
require 'json'
require_relative 'utils'

Sequel.migration do
  up do
    reindex_types = [:agent_person, :agent_software, :agent_family,
                     :agent_corporate_entity]

    reindex_types.each do |table|
      self[table].update(:system_mtime => Time.now)
    end

    self[:note].each do |row|
      old_note = JSON.parse(row[:notes])
      if old_note["jsonmodel_type"] == "note_agent_rights_statement"
        new_note = JSON.generate({
                                   'jsonmodel_type' => 'note_general_context',
                                   'persistent_id' => old_note['persistent_id'],
                                   'subnotes' => [{
                                                    'jsonmodel_type' => 'note_text',
                                                    'content' => old_note['content']
                                                  }]
                                 })
        self[:note]
          .filter(:id => row[:id])
          .update(:notes => blobify(self, new_note))
      end
    end
  end

  down do
  end
end
