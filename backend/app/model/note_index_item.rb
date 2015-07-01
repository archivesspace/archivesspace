class NoteIndexItem < Sequel::Model(:note_index_item)

  include ASModel
  corresponds_to JSONModel(:note_index_item)

end
