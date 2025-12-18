class DefaultValues < Sequel::Model(:default_values)
  include ASModel
  corresponds_to JSONModel(:default_values)

  set_model_scope :repository

  def self.create_or_update(json, repo_id, record_type)
    remove_resolved_references(json)

    id = "#{repo_id}_#{record_type}"

    if self[id]
      self[id].update_from_json(json)
    else
      self.create_from_json(json, {:id => "#{repo_id}_#{record_type}"})
    end

    self[id]
  end

  def self.remove_resolved_references(json)
    record_schema = JSONModel(json.record_type.to_sym).schema
    ref_properties = extract_ref_properties(record_schema)

    ref_properties.each do |property|
      Array(json.defaults[property]).each { |o| o.delete('_resolved') }
    end
  end

  def self.to_jsonmodel(obj, opts = {})
    if obj.is_a? String
      obj = DefaultValues[obj]
      raise NotFoundException.new("#{self} not found") unless obj
    end

    self.sequel_to_jsonmodel([obj], opts)[0]
  end


  # Recursively extract all property names that are refs from a schema
  def self.extract_ref_properties(schema, prefix = [])
    properties = []
    return properties unless schema && schema['properties']

    schema['properties'].each do |prop_name, prop_def|
      current_path = prefix + [prop_name]

      if prop_def['subtype'] == 'ref'
        properties << current_path.join('::')
      end

      if prop_def['type'] == 'array' && prop_def['items']
        items_def = prop_def['items']

        items_defs = items_def.is_a?(Array) ? items_def : [items_def]

        items_defs.each do |item_def|
          if item_def['subtype'] == 'ref'
            properties << current_path.join('::')
          elsif item_def['properties']
            properties.concat(extract_ref_properties(item_def, current_path))
          end
        end
      end

      if prop_def['type'] == 'object' && prop_def['properties']
        properties.concat(extract_ref_properties(prop_def, current_path))
      end
    end

    properties
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = objs.map do |obj|
      json = JSONModel(:default_values).new(ASUtils.json_parse(obj[:blob]))
      json.uri = obj.uri
      json.lock_version = obj.lock_version
      resolve_references(json)

      json
    end

    jsons
  end

  def self.resolve_references(json)
    record_schema = JSONModel(json.record_type.to_sym).schema
    ref_properties = extract_ref_properties(record_schema)
    container = {'defaults' => json.defaults}
    properties_to_resolve = ref_properties.map { |prop| "defaults::#{prop}" }

    if !properties_to_resolve.empty?
      resolved_container = URIResolver.resolve_references(container, properties_to_resolve)
      json.defaults = resolved_container['defaults']
    end
  rescue => e
    Log.warn("Failed to resolve references in default_values: #{e.message}")
    Log.debug(e.backtrace.join("\n"))
  end

  def self.create_from_json(json, opts = {})
    super(json, opts.merge('blob' => json.to_json))
  end


  def update_from_json(json, opts = {}, apply_nested_records = false)
    json['lock_version'] ||= 0
    super(json, opts.merge('blob' => json.to_json))
  end


  def uri
    "/repositories/#{self.repo_id}/default_values/#{self.record_type}"
  end

end


DefaultValues.unrestrict_primary_key
