class NoteOrderedlist < Sequel::Model(:note_orderedlist)

  include ASModel
  corresponds_to JSONModel(:note_orderedlist)

end
