class NoteIndex < Sequel::Model(:note_index)

  include ASModel
  corresponds_to JSONModel(:note_index)

end
