class SearchResolverCompactResource

  FIELDS_TO_KEEP = ['id_0', 'id_1', 'id_2', 'id_3', 'level', 'other_level', 'title', 'display_string', 'uri', 'publish']

  # Really just including this as a demo.  Let's parse the JSON and extract a few fields.
  def resolve(record)
    resource = ASUtils.json_parse(record['json'])
    resource.select {|key, _| FIELDS_TO_KEEP.include?(key)}
  end

  SearchResolver.add_custom_resolver('compact_resource', self)

end
