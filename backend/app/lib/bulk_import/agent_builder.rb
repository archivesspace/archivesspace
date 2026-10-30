class AgentBuilder
  attr_reader :errors

  def initialize(attributes:, controlled_value_resolver:)
    @errors = []
    canonicalize(attributes, controlled_value_resolver)
    @errors.freeze
  end

  def to_h
    values(:derived => true)
  end

  def supplied_values
    values(:derived => false)
  end

  def source_of(path)
    return { :attribute => :publish } if path == ["publish"]

    key, _index, property, nested_index, nested_property = path
    case key
    when "names"
      { :record => :name, :attribute => attribute_for(property) }
    when "agent_contacts"
      if property == "telephones"
        { :record => :contact, :nested => @telephone_keys[nested_index], :attribute => nested_property.to_sym }
      else
        { :record => :contact, :attribute => property.to_sym }
      end
    when "notes"
      { :record => :note, :attribute => @subnote_attributes[nested_index] }
    end
  end

  private

  def values(derived:)
    raise ArgumentError, "AgentBuilder values require an error-free builder" unless @errors.empty?

    agent = {
      "jsonmodel_type" => "agent_#{@agent_type}",
      "names" => [derived ? @name.merge(@name_derived) : @name],
    }
    agent["agent_contacts"] = [contact_values(derived)] if @contact
    agent["notes"] = [@note] if @note
    agent["publish"] = @publish unless @publish.nil?
    agent
  end

  def contact_values(derived)
    return @contact if @telephones.empty?

    telephones = derived ? @telephones.zip(@telephone_derived).map { |telephone, values| telephone.merge(values) } : @telephones
    @contact.merge("telephones" => telephones)
  end

  def canonicalize(attributes, resolver)
    canonicalize_agent_type(attributes[:agent_type])
    return unless @errors.empty?

    canonicalize_publish(attributes[:publish])
    canonicalize_name(attributes[:name] || {}, resolver)
    canonicalize_contact(attributes[:contact] || {}, resolver)
    canonicalize_note(attributes[:note] || {})
  end

  def canonicalize_agent_type(submitted)
    if submitted.to_s.strip.empty?
      add_error(:required, :agent_type)
      return
    end

    @agent_type = AgentHandler.import_agent_type(submitted)
    add_error(:unsupported, :agent_type, submitted) unless @agent_type
  end

  def canonicalize_publish(value)
    return if blank?(value)

    @publish = ASpaceImport::Utils.normalize_boolean.call(value)
  rescue ASpaceImport::Utils::UnrecognizedBooleanValue
    add_error(:invalid, :publish, value)
  end

  def canonicalize_name(submitted, resolver)
    @name = canonicalize_record(:name, name_type, submitted, resolver)
    @name_derived = @name.key?("sort_name") ? { "sort_name_auto_generate" => false } : {}
  end

  def canonicalize_contact(submitted, resolver)
    return if all_blank?(submitted)

    schema = JSONModel(:agent_contact).schema["properties"]
    scalars, nested = submitted.partition { |_attribute, value| !value.is_a?(Hash) }.map(&:to_h)
    @contact = canonicalize_record(:contact, :agent_contact, scalars, resolver)
    telephones = nested.filter_map do |key, values|
      record, derived = canonicalize_nested_record(:contact, key, values, schema, resolver)
      [key, record, derived] if record
    end
    @telephone_keys = telephones.map(&:first)
    @telephones = telephones.map { |_key, record, _derived| record }
    @telephone_derived = telephones.map(&:last)
  end

  def canonicalize_nested_record(parent, key, submitted, schema, resolver)
    return if all_blank?(submitted)

    item_type, enum_value = nested_target(schema, key, resolver)
    if item_type.nil?
      submitted.each { |attribute, value| add_error(:incompatible, attribute, value, parent, key) unless blank?(value) }
      return
    end

    record = canonicalize_record(parent, item_type, submitted, resolver, key)
    defaulted = item_type == key
    record.merge!(enum_value) unless defaulted
    add_error(:required, :number, nil, parent, key) if item_type == :telephone && record.key?("ext") && !record.key?("number")
    [record, defaulted ? enum_value : {}]
  end

  def nested_target(schema, key, resolver)
    schema.each_value do |definition|
      item_type = array_item_type(definition)
      next unless item_type

      enum_property, enum_definition = JSONModel(item_type).schema["properties"].find { |_property, item| item["dynamic_enum"] }
      return [item_type, default_enum_value(enum_property, enum_definition, resolver)] if item_type == key
      next unless enum_definition

      value = resolver.call(enum_definition["dynamic_enum"], key.to_s)
      return [item_type, { enum_property => value }] if value
    end
    nil
  end

  def default_enum_value(property, definition, resolver)
    return {} unless definition

    value = resolver.call(definition["dynamic_enum"], "home")
    value ? { property => value } : {}
  end

  def array_item_type(definition)
    return nil unless definition["type"] == "array"

    item = definition.dig("items", "type")
    match = item.is_a?(String) && item.match(/\AJSONModel\(:(\w+)\) object\z/)
    match ? match[1].to_sym : nil
  end

  def canonicalize_note(submitted)
    allowed = note_subnote_types
    subnotes = submitted.filter_map do |attribute, value|
      next if blank?(value)

      type = attribute == :content ? :note_text : :"note_#{attribute}"
      unless allowed.include?(type)
        add_error(:incompatible, attribute, value, :note)
        next
      end

      array = JSONModel(type).schema["properties"]["content"]["type"] == "array"
      [attribute, { "jsonmodel_type" => type.to_s, "content" => array ? [freeze_copy(value)] : freeze_copy(value) }]
    end
    @subnote_attributes = subnotes.map(&:first)
    @note = { "jsonmodel_type" => "note_bioghist", "subnotes" => subnotes.map(&:last) } unless subnotes.empty?
  end

  def note_subnote_types
    JSONModel(:note_bioghist).schema["properties"]["subnotes"]["items"]["type"].map do |item|
      item["type"][/\AJSONModel\(:(\w+)\) object\z/, 1].to_sym
    end
  end

  def canonicalize_record(record, type, submitted, resolver, nested = nil)
    schema = JSONModel(type).schema["properties"]
    result = { "jsonmodel_type" => type.to_s }
    submitted.each do |attribute, value|
      next if blank?(value)

      property = schema_property(attribute)
      if schema.key?(property)
        canonicalize_value(result, [record, nested], attribute, property, value, schema[property]["dynamic_enum"], resolver)
      else
        add_error(:incompatible, attribute, value, record, nested)
      end
    end
    require_properties(result, schema, record, nested)
    result
  end

  def canonicalize_value(result, scope, attribute, property, value, enum_list, resolver)
    if enum_list.nil?
      result[property] = freeze_copy(value)
      return
    end

    canonical = resolver.call(enum_list, value)
    if canonical.nil?
      add_error(:invalid, attribute, value, *scope)
    else
      result[property] = freeze_copy(canonical)
    end
  end

  def require_properties(result, schema, record, nested)
    schema.each do |property, definition|
      next unless definition["ifmissing"] == "error"
      next if result.key?(property)
      next if @errors.any? { |error| error[:record] == record && error[:nested] == nested && schema_property(error[:attribute]) == property }

      add_error(:required, attribute_for(property), nil, record, nested)
    end
  end

  def name_type
    :"name_#{@agent_type}"
  end

  def schema_property(attribute)
    attribute == :primary_name && @agent_type == "family" ? "family_name" : attribute.to_s
  end

  def attribute_for(property)
    property == "family_name" ? :primary_name : property.to_sym
  end

  def add_error(code, attribute, value = nil, record = nil, nested = nil)
    error = {
      :code => code,
      :record => record,
      :attribute => attribute,
      :value => freeze_copy(value),
    }
    error[:nested] = nested if nested
    @errors << error.freeze
  end

  def all_blank?(submitted)
    submitted.values.all? { |value| value.is_a?(Hash) ? all_blank?(value) : blank?(value) }
  end

  def blank?(value)
    value.nil? || value == ""
  end

  def freeze_copy(value)
    value.is_a?(String) ? -value : value
  end
end
