# A common base class for all JSONModel classes
class JSONModelType

  # Class instance variables store the bits specific to this model
  def self.init(type, schema, mixins = [])
    @record_type = type
    @schema = schema

    # In client mode, mix in some extra convenience methods for querying the
    # ArchivesSpace backend service via HTTP.
    if JSONModel.client_mode?
      require_relative 'jsonmodel_client'
      include JSONModel::Client
    end


    define_accessors(schema['properties'].keys)


    mixins.each do |mixin|
      include(mixin)
    end
  end


  # If a JSONModel is extended, make its schema and record type class variables
  # available on the subclass too.
  def self.inherited(child)
    child.instance_variable_set(:@schema, schema)
    child.instance_variable_set(:@record_type, record_type)
  end


  # Return the JSON schema that defines this JSONModel class
  def self.schema
    @schema
  end


  # Return the version number of this JSONModel's schema
  def self.schema_version
    self.schema['version']
  end


  # Return the type of this JSONModel class (a keyword like
  # :archival_object)
  def self.record_type
    @record_type
  end


  def self.to_s
    "JSONModel(:#{self.record_type})"
  end


  # Add a custom validation to this model type.
  #
  # The validation is a block that takes a hash of properties and returns an array of pairs like:
  # [["propertyname", "the problem with it"], ...]
  def self.add_validation(name, level = :error, &block)
    raise "Validation name already taken: #{name}" if JSONModel.custom_validations[name]

    JSONModel.custom_validations[name] = block

    self.schema["validations"] ||= []
    self.schema["validations"] << [level, name]
  end


  # Create an instance of this JSONModel from the data contained in 'hash'.
  def self.from_hash(hash, raise_errors = true, trusted = false)
    hash["jsonmodel_type"] = self.record_type.to_s

    # If we're running in client mode, leave 'readonly' properties in place,
    # since they're intended for use by clients.  Otherwise, we drop them.
    drop_system_properties = !JSONModel.client_mode?

    if trusted
      # We got this data from a trusted source (such as another JSONModel
      # that had already been validated itself).  No need to double up
      self.new(hash, true)
    else
      cleaned = JSONSchemaUtils.drop_unknown_properties(hash, self.schema, drop_system_properties)
      cleaned = ASUtils.jsonmodels_to_hashes(cleaned)

      validate(cleaned, raise_errors)

      self.new(cleaned)
    end
  end


  # Create an instance of this JSONModel from a JSON string.
  def self.from_json(s, raise_errors = true)
    self.from_hash(ASUtils.json_parse(s), raise_errors)
  end


  def self.uri_and_remaining_options_for(id = nil, opts = {})
    # Some schemas (like name schemas) don't have a URI because they don't
    # need endpoints.  That's fine.
    if not self.schema['uri']
      return nil
    end

    uri = self.schema['uri']

    if not id.nil?
      uri += "/#{self.escape_uri_component(id.to_s)}"
    end

    self.substitute_parameters(uri, opts)
  end


  # Given a numeric internal ID and additional options produce a pair containing a URI reference.
  # For example:
  #
  #     JSONModel(:archival_object).uri_for(500, :repo_id => 123)
  #
  #  might yield "/repositories/123/archival_objects/500"
  #
  def self.uri_for(id = nil, opts = {})
    result = self.uri_and_remaining_options_for(id, opts)

    result ? result[0] : nil
  end


  # The inverse of uri_for:
  #
  #     JSONModel(:archival_object).id_for("/repositories/123/archival_objects/500", :repo_id => 123)
  #
  #  might yield 500
  #
  # IDs are either positive integers, or importer-provided logical IDs
  ID_REGEXP = /([0-9]+|import_[a-f0-9-]+)/

  def self.id_for(uri, opts = {}, noerror = false)
    if not self.schema['uri']
      if noerror
        return nil
      else
        raise "Missing a URI definition for class #{self.class}"
      end
    end

    pattern = self.schema['uri']
    pattern = pattern.gsub(/\/:[a-zA-Z_]+(\/|$)/, '/[^/ ]+\1')

    if uri =~ /#{pattern}\/#{ID_REGEXP}(\#.*)?$/
      return id_to_int($1)
    elsif uri =~ /#{pattern.gsub(/\[\^\/ \]\+\/tree/, '')}#{ID_REGEXP}\/(tree|ordered_records)$/
      # FIXME: gross hardcoding...
      return id_to_int($1)
    else
      if noerror
        nil
      else
        raise "Couldn't make an ID out of URI: #{uri}"
      end
    end
  end


  # Return the type of the schema property defined by 'path'
  #
  # For example, type_of("names/items/type") might return a JSONModel class
  def self.type_of(path)
    type = JSONSchemaUtils.schema_path_lookup(self.schema, path)["type"]

    ref = JSONModel.parse_jsonmodel_ref(type)

    if ref
      JSONModel.JSONModel(ref.first)
    else
      Kernel.const_get(type.capitalize)
    end
  end


  def initialize(params = {}, trusted = false)
    set_data(params)

    @uri ||= params['uri']

    # a hash to store transient instance data
    @instance_data = {}

    self.class.define_accessors(@data.keys)

    if trusted
      @validated = {}
      @cleaned_data = @data
    end
  end


  attr_reader :uri

  def uri=(val)
    @uri = val
    self['uri'] = val
  end

  def instance_data
    @instance_data
  end


  def [](key)
    @data[key.to_s]
  end


  def []=(key, val)
    @validated = false
    @data[key.to_s] = val
  end


  def has_key?(key)
    @data.has_key?(key)
  end
  alias :key? :has_key?


  # Validate the current JSONModel instance and return a list of exceptions
  # produced.
  def _exceptions
    return @validated if @validated && @errors.nil?

    exceptions = {}
    if not @always_valid
      exceptions = self.validate(@data, false)
    end

    if @errors
      exceptions[:errors] = (exceptions[:errors] or {}).merge(@errors)
    end

    exceptions
  end


  def clear_errors
    # reset validation
    @validated = false
    @errors = nil
  end


  def add_error(attribute, message)
    # reset validation
    @validated = false

    # call JSONModel::Client's version
    super
  end


  def _warnings
    exceptions = self._exceptions

    if exceptions.has_key?(:warnings)
      exceptions[:warnings]
    else
      []
    end
  end


  # Set this object instance to always pass validation.  Used so the
  # frontend can create intentionally incomplete objects that will be filled
  # out by the user.
  def _always_valid!
    @always_valid = true
    self
  end


  # Update the values of the current JSONModel instance with the contents of
  # 'params', validating before accepting the update.
  def update(params)
    @validated = false
    replace(ASUtils.deep_merge(@data, params))
  end

  # Update the values of the current JSONModel instance with the contents of
  # 'params', validating before accepting the update.
  def update_concat(params)
    @validated = false
    replace(ASUtils.deep_merge_concat(@data, params))
  end

  # Replace the values of the current JSONModel instance with the contents
  # of 'params', validating before accepting the replacement.
  def replace(params)
    @validated = false
    set_data(params)
  end


  def reset_from(another_jsonmodel)
    @data = another_jsonmodel.instance_eval { @data }
  end


  def to_s
    "#<JSONModel(:#{self.class.record_type}) #{@data.inspect}>"
  end


  def inspect
    self.to_s
  end


  # Produce a (possibly nested) hash from the values of this JSONModel.  Any
  # values that don't appear in the JSON schema will not appear in the
  # result.
  def to_hash(mode = nil)
    mode = (mode || :validated)

    raise "Invalid .to_hash mode: #{mode}" unless [:trusted, :validated, :raw].include?(mode)

    return @data if mode == :raw

    if @validated and @cleaned_data
      return @cleaned_data
    end

    cleaned = JSONSchemaUtils.drop_unknown_properties(@data, self.class.schema)
    cleaned = ASUtils.jsonmodels_to_hashes(cleaned)

    if mode == :validated
      @validated = false
      self.validate(cleaned)
    end

    @cleaned_data = cleaned
  end


  # Produce a JSON string from the values of this JSONModel.  Any values
  # that don't appear in the JSON schema will not appear in the result.
  def to_json(opts = {})
    ASUtils.to_json(self.to_hash(opts[:mode]), opts.is_a?(Hash) ? opts.merge(:max_nesting => false) : {})
  end


  # Return the internal ID of this JSONModel.
  def id
    ref = JSONModel::parse_reference(self.uri)

    if ref
      ref[:id]
    else
      nil
    end
  end


  protected


  def validate(data, raise_errors = true)
    @validated = self.class.validate(data, raise_errors)
  end


  # Validate the supplied hash using the JSON schema for this model.  Raise
  # a ValidationException if there are any fatal validation problems, or if
  # strict mode is enabled and warnings were produced.
  def self.validate(hash, raise_errors = true)
    properties = JSONSchemaUtils.drop_unknown_properties(hash, self.schema)
    ValidatorCache.with_validator_for(self, properties) do |validator|

      messages = validator.validate
      exceptions = JSONSchemaUtils.parse_schema_messages(messages, validator)

      if raise_errors && (!exceptions[:errors].empty? || (JSONModel.strict_mode? && !exceptions[:warnings].empty?))
        raise JSONModel::ValidationException.new(:invalid_object => self.new(hash),
                                      :warnings => exceptions[:warnings],
                                      :errors => exceptions[:errors],
                                      :attribute_types => exceptions[:attribute_types])
      end

      exceptions.reject {|k, v| v.empty?}
    end
  end


  # Given a URI template like /repositories/:repo_id/something/:somevar, and
  # a hash containing keys and replacement strings, return [uri, opts],
  # where 'uri' is the template with values substituted for their
  # placeholders, and 'opts' is any parameters that weren't consumed.
  #
  def self.substitute_parameters(uri, opts = {})
    matched = []
    opts.each do |k, v|
      old = uri
      uri = uri.gsub(":#{k}", self.escape_uri_component(v.to_s))

      if old != uri

        if v.is_a? Symbol
          raise ("Tried to substitute the value '#{v.inspect}' for ':#{k}'." +
                 "  This is usually a sign that something has gone wrong" +
                 " further up the stack. (URI was: '#{uri}')")
        end

        # Matched on this parameter.  Remove it from the passed in hash
        matched << k
      end
    end

    if uri.include?(":")
      raise "Template substitution was incomplete: '#{uri}'"
    end

    remaining_opts = opts.clone
    matched.each do |k|
      remaining_opts.delete(k)
    end

    [uri, remaining_opts]
  end


  private

  def self.escape_uri_component(string)
    CGI.escape(string).gsub("+", "%20")
  end

  # Define accessors for all variable names listed in 'attributes'
  def self.define_accessors(attributes)
    attributes.each do |attribute|

      if not method_defined? "#{attribute}"
        define_method "#{attribute}" do
          @data[attribute]
        end
      end


      if not method_defined? "#{attribute}="
        define_method "#{attribute}=" do |value|
          @validated = false
          @data[attribute] = JSONModel.clean_data(value)
        end
      end
    end
  end


  def self.id_to_int(id)
    if id =~ /^import_/
      id
    else
      id.to_i
    end
  end


  def set_data(data)
    hash = JSONModel.clean_data(data)
    hash["jsonmodel_type"] = self.class.record_type.to_s
    hash = JSONSchemaUtils.apply_schema_defaults(hash, self.class.schema)

    @data = hash
  end


  def self.properties_by_tag(tag)
    @schema['properties'].find_all { |p, cfg| cfg.fetch('tags', []).include?(tag) }
  end
end
