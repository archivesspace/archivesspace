class NoteLangMaterial < Sequel::Model(:note_langmaterial)

  include ASModel
  corresponds_to JSONModel(:note_langmaterial)

end
