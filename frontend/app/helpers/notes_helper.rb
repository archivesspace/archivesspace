module NotesHelper

  def note_types_for(jsonmodel_type)
    note_types = {"bibliography" => :note_bibliography}

    if jsonmodel_type =~ /digital_object/

      # Digital object/digital object component
      JSONModel(:note_digital_object).schema['properties']['type']['enum'].each do |type|
        note_types[type] = :note_digital_object
      end

    else

      # Resource/AO
      JSONModel(:note_singlepart).schema['properties']['type']['enum'].each do |type|
        note_types[type] = :note_singlepart
      end

      JSONModel(:note_multipart).schema['properties']['type']['enum'].each do |type|
        note_types[type] = :note_multipart
      end

      note_types["index"] = :note_index
    end

    note_types
  end
end
