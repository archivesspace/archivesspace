class NoteSinglepart < Sequel::Model(:note_singlepart)

  include ASModel
  corresponds_to JSONModel(:note_singlepart)

end
