# Convenience methods for getting particular subrecords
# out of json objects or hashes

def get_note(obj, id)
  obj['notes'].find{|n| n['persistent_id'] == id}
end


def get_notes_by_type(obj, note_type)
  obj['notes'].select{|n| n['type'] == note_type}
end


def get_note_by_type(obj, note_type)
  get_notes_by_type(obj, note_type)[0]
end


def get_subnotes_by_type(obj, note_type)
  obj['subnotes'].select {|sn| sn['jsonmodel_type'] == note_type}
end


def note_content(note)
  if note['content']
    Array(note['content']).join(" ")
  else
    get_subnotes_by_type(note, 'note_text').map {|sn| sn['content']}.join(" ").gsub(/\n +/, "\n")
  end
end


def get_notes_by_string(notes, string)
  notes.select {|note| (note.has_key?('subnotes') && note['subnotes'][0]['content'] == string) \
    || (note['content'].is_a?(Array) && note['content'][0] == string) }
end


def get_family_by_name(families, famname)
  families.find {|f| f['names'][0]['family_name'] == famname}
end


def get_person_by_name(people, primary_name)
  people.find {|p| p['names'][0]['primary_name'] == primary_name}
end


def get_corp_by_name(corps, primary_name)
  corps.find {|c| c['names'][0]['primary_name'] == primary_name}
end
