class RequiredFields

  def self.get(record_type)
    uri = "/repositories/#{JSONModel.repository}/required_fields/#{record_type}"
    begin
      result = JSONModel::HTTP.get_json(uri)
      self.new(JSONModel(:required_fields).from_hash(result))
    rescue RecordNotFound => e
      self.new(JSONModel(:required_fields).from_hash(record_type: record_type))
    end
  end

  def self.from_hash(hash)
    self.new(JSONModel(:required_fields).from_hash(hash))
  end

  def initialize(json)
    @json = json
  end

  def method_missing(meth, *args)
    @json.send(meth, *args)
  end

  def save
    uri = "/repositories/#{JSONModel.repository}/required_fields/#{@json.record_type}"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json((@json.to_hash)))

    if response.code != '200'
      raise response.body
    end

    response
  end

  # this is limited to checking for subrecord presence and checking presence of fields
  # of subrecords that are immediately attached to a property of the top-level record
  # as an array, but could be expanded to cover other parts of the record
  def add_errors(obj)
    unless obj.jsonmodel_type == @json.record_type
      raise "Cannot validate a #{obj.jsonmodel_type} with these #{@json.record_type} requirements!"
    end
    @json.subrecord_requirements.each do |requirements|
      property = requirements["property"]
      type = requirements["record_type"]

      # see comment below
      if obj[property].present?
        obj[property].each_with_index do |subrecord, i|
          next unless subrecord.is_a?(Hash)
          next if subrecord['jsonmodel_type'] && subrecord['jsonmodel_type'].to_s != requirements['record_type']
          requirements['required_fields'].each do |required_field|
            unless subrecord[required_field].present?
              obj.add_error("#{property}/#{i}/#{required_field}", :missing_required_property)
            end
          end
        end
      elsif requirements["required"]
        obj.add_error(property, :missing_required_subrecord)
      end
    end
  end

  # Ideally a subrecord field requirement should probably involve:
  #  1) a property of the parent schema;
  #  2) the type of subrecord;
  #  3) the field name
  # But since form data carried through an invalid create attempt is missing #2,
  # and javascript templates lack #1, and furthermore migrated requirements don't
  # have record types; and since in practice there is generally
  # only one model type that will satisfy a property (e.g.,
  # "metadata_rights_declarations / metadata_rights_declaration"), we
  # will accept nil for either property or type (on either side for type),
  # and assume it's a match. caveat validator.
  def required?(property, type, field = nil)
    @json.subrecord_requirements.each do |requirements|
      next unless type.nil? || requirements['record_type'].nil? || requirements['record_type'] == type.to_s
      next unless property.nil? || requirements['property'] == property.to_s
      return true if property && type && field.nil? && requirements['required']
      return true if requirements['required_fields'].include?(field.to_s) && field.present?
    end
    false
  end

  def each_required_subrecord
    @json.subrecord_requirements.each do |requirements|
      next unless requirements['required']
      yield requirements['property'], { 'jsonmodel_type' => requirements['record_type'] }
    end
  end
end
