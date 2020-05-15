Sequel.migration do
  up do
    $stderr.puts("add 'ingest' to name_source")
    enum, value = "name_source", "ingest"
    e_id = self[:enumeration].filter(name: enum).get(:id)
    v_id = self[:enumeration_value].filter(enumeration_id: e_id, value: value).get(:id)
    unless v_id
      pos = self[:enumeration_value].filter(enumeration_id: e_id).max(:position) + 1
      self[:enumeration_value].insert(
        enumeration_id: e_id, value: value, position: pos,
      )
    end
  end
end
