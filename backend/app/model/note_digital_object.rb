class NoteDigitalObject < Sequel::Model(:note_digital_object)

  include ASModel
  corresponds_to JSONModel(:note_digital_object)

end
