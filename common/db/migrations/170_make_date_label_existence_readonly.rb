require_relative 'utils'

Sequel.migration do

  up do
    $stderr.puts("Fixing digital_object enumeration value for instance_type - make sure it's there and make it readonly")

    enum_id = self[:enumeration].filter(name: 'date_label').get(:id)

    if self[:enumeration_value].filter(enumeration_id: enum_id, value: 'existence').count == 0
      # oops, someone deleted it - recreate it!
      now = Time.now

      pos = self[:enumeration_value].filter(enumeration_id: enum_id).max(:position) + 1

      self[:enumeration_value].insert(
                                      enumeration_id: enum_id,
                                      value: 'existence',
                                      readonly: 1,
                                      position: pos,
                                      json_schema_version: 1,
                                      created_by: 'admin',
                                      create_time: now,
                                      system_mtime: now,
                                      user_mtime: now
                                      )
    else
      # phew it lives! - make it readonly
      self[:enumeration_value].filter(enumeration_id: enum_id, value: 'existence').update(readonly: 1)
    end
  end


  down do
    # no going back
  end

end
