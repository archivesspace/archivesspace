require_relative 'utils'

Sequel.migration do
  up do
    # Ensure file_version_file_format_name.iiif exists
    file_format_name_enum_id = self[:enumeration]
                .filter(:name => 'file_version_file_format_name')
                .get(:id)

    next_position = self[:enumeration_value]
                      .filter(:enumeration_id => file_format_name_enum_id)
                      .max(:position) + 1

    enum_exists = self[:enumeration_value]
                    .filter(:enumeration_id => file_format_name_enum_id,
                            :value => 'iiif')
                    .count == 1

    unless enum_exists
      self[:enumeration_value]
        .insert(:enumeration_id => file_format_name_enum_id,
                :value => 'iiif',
                :position => next_position)
    end

    # Ensure file_version_use_statement.text-json
    use_statement_enum_id = self[:enumeration]
                .filter(:name => 'file_version_use_statement')
                .get(:id)

    next_position = self[:enumeration_value]
                      .filter(:enumeration_id => use_statement_enum_id)
                      .max(:position) + 1

    enum_exists = self[:enumeration_value]
                    .filter(:enumeration_id => use_statement_enum_id,
                            :value => 'text-json')
                    .count == 1

    unless enum_exists
      self[:enumeration_value]
        .insert(:enumeration_id => use_statement_enum_id,
                :value => 'text-json',
                :position => next_position)
    end
  end
end
