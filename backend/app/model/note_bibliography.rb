class NoteBibliography < Sequel::Model(:note_bibliography)

  include ASModel
  corresponds_to JSONModel(:note_bibliography)

end
