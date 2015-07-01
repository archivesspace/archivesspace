class NoteMultipart < Sequel::Model(:note_multipart)

  include ASModel
  corresponds_to JSONModel(:note_multipart)

end
