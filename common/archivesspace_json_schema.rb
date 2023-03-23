require 'date'

# Add a new 'ifmissing' attribute which emits either an error or warning
# depending on its value.
class IfMissingAttribute < JSON::Schema::PropertiesAttribute

  def self.validate(current_schema, data, fragments, validator, options = {})
    super

    if data.is_a?(Hash)
      current_schema.schema['properties'].each do |property, property_schema|
        if (property_schema['ifmissing'] && !data.has_key?(property))
          message = nil

          if property_schema['ifmissing'] == 'error'
            message = "ERROR: The property '#{build_fragment(fragments)}' did not contain a required property of '#{property}'"
          elsif property_schema['ifmissing'] == 'warn'
            message = "WARNING: The property '#{build_fragment(fragments)}' did not contain a required property of '#{property}'"
          end

          if message
            validation_error(message, fragments, current_schema, self, options[:record_errors])
          end
        end
      end
    end
  end

end


class ArchivesSpaceTypeAttribute < JSON::Schema::TypeAttribute
  extend JSONModel


  # This reuse business is a bit of a pain.  The story here: JRuby backtraces
  # are relatively expensive to create (relative to MRI Ruby), and JSON Schema
  # validation is using exceptions as control flow here (sigh).  During imports,
  # these validation error are hit a *lot*, and calculating a backtrace every
  # time is expensive.
  #
  # So, we recycle.
  def self.validation_error_for(expected_type, fragments, current_schema)
    Thread.current[:json_validation_cached_errors] ||= {}
    if !Thread.current[:json_validation_cached_errors][expected_type]
      msg = "ERROR: Schema type mismatch.  Expected type: #{expected_type}"
      Thread.current[:json_validation_cached_errors][expected_type] = JSON::Schema::ValidationError.new(msg, fragments, self, current_schema)
    end

    Thread.current[:json_validation_cached_errors][expected_type].fragments = fragments
    Thread.current[:json_validation_cached_errors][expected_type]
  end


  def self.validate(current_schema, data, fragments, validator, options = {})
    types = current_schema.schema['type']

    if types == 'date'
      begin
        Date.parse(data)
        return
      rescue
        validation_error("The property '#{build_fragment(fragments)}' was not " +
                         "a well-formed date (value: #{data})",
                         fragments, current_schema, self, options[:record_errors])
      end
    end

    if types == 'object' && data.is_a?(Hash) && data.has_key?('ref') && current_schema.schema['subtype'] != 'ref'
      # Provide a helpful warning about potentially missing subtype definitions
      $stderr.puts("WARNING: Schema #{current_schema.inspect} appears to be missing a subtype definition of 'ref'")
    end

    # A bit crazy, sorry.  If we're being asked to validate a hash whose
    # jsonmodel_type is marked against a different JSONModel schema, we're
    # wasting our time.  Just stop straight away.
    if (data.is_a?(Hash) && data["jsonmodel_type"]) &&
        (current_schema.schema.is_a?(Hash) &&
         "#{current_schema.schema["type"]}".include?("JSONModel") &&
         !"#{current_schema.schema["type"]}".include?("JSONModel(:#{data['jsonmodel_type']})"))

      raise validation_error_for(data['jsonmodel_type'], fragments, current_schema)
    end

    if JSONModel.parse_jsonmodel_ref(types)
      (model, qualifier) = JSONModel.parse_jsonmodel_ref(types)

      if qualifier == 'uri' || (qualifier == 'uri_or_object' && data.is_a?(String))
        if JSONModel(model).id_for(data, {}, true).nil?
          validation_error("The property '#{build_fragment(fragments)}' of type " +
                           "#{data.class} did not match the following type: #{types} in schema",
                           fragments, current_schema, self, options[:record_errors])
        end

      elsif qualifier == 'uri_or_object' || qualifier == 'object'
        if data.is_a?(Hash)
          data["jsonmodel_type"] ||= model.to_s

          ValidatorCache.with_validator_for(JSONModel(model), data) do |subvalidator|
            # Urk.  Validate the subrecord but pass in the fragments of the point
            # we're at in the parent record.
            subvalidator.instance_eval do
              @base_schema.validate(@data, fragments, @validation_options)
            end
          end

        else
          validation_error("The property '#{build_fragment(fragments)}' of type " +
                           "#{data.class} did not match the following type: #{types} in schema",
                           fragments, current_schema, self, options[:record_errors])
        end
      end
    else
      super
    end
  end
end


class ArchivesSpaceSubTypeAttribute < JSON::Schema::TypeAttribute

  def self.validate(current_schema, data, fragments, validator, options = {})
    if data.is_a?(Hash) && !data.has_key?('ref')
      message = "ERROR: The property '#{build_fragment(fragments)}' did not contain a required property of 'ref'"
      validation_error(message, fragments, current_schema, self, options[:record_errors])
    end
  end

end

class ArchivesSpaceReadOnlyDynamicEnumAttribute < JSON::Schema::TypeAttribute; end

class ArchivesSpaceDynamicEnumAttribute < JSON::Schema::TypeAttribute

  def self.validate(current_schema, data, fragments, validator, options = {})
    enum_name = current_schema.schema['dynamic_enum']

    if !JSONModel.init_args[:enum_source].valid?(enum_name, data)
      possible_values = JSONModel.init_args[:enum_source].values_for(enum_name)
      message = ("The property '#{build_fragment(fragments)}' value #{data.inspect} " +
                 "did not match one of the following configurable values: #{possible_values.join(', ')}")

      # 11/26/18: added this check because many Selenium tests were failing here with a NoMethodError
      enum_source = JSONModel.init_args[:enum_source]
      if enum_source.respond_to?(:editable?) &&
         enum_source.editable?(enum_name)

        klass = self
      else
        klass = ArchivesSpaceReadOnlyDynamicEnumAttribute
      end

      validation_error(message, fragments, current_schema, klass, options[:record_errors])
    end
  end

end


class ArchivesSpaceSchema < JSON::Schema::Validator
  def initialize
    super
    extend_schema_definition("http://json-schema.org/draft-03/schema#")
    @attributes["type"] = ArchivesSpaceTypeAttribute
    @attributes["subtype"] = ArchivesSpaceSubTypeAttribute
    @attributes["dynamic_enum"] = ArchivesSpaceDynamicEnumAttribute
    @attributes["properties"] = IfMissingAttribute
    @uri = URI.parse("http://www.archivesspace.org/archivesspace.json")
  end


  def already_failed?(fragments)
    JSON::Validator.validation_errors.any? {|error|
      error.fragments == fragments
    }
  end


  def validate(current_schema, data, fragments, options = {})
    super

    # Run any custom validations if we've made it this far with no errors
    if !already_failed?(fragments) && current_schema.schema.has_key?("validations")
      current_schema.schema["validations"].each do |level_and_name|
        level, name = level_and_name

        errors = JSONModel::custom_validations[name].call(data)

        errors.each do |error|
          error_string = nil

          if error.is_a? Symbol
            error_string = "Validation error code: #{error}"
          else
            field, msg = error
            prefix = level == :warning ? "Warning generated for" : "Validation failed for"
            error_string = "#{prefix} '#{field}': #{msg}"

          end

          err = JSON::Schema::ValidationError.new(error_string,
                                                  fragments,
                                                  "custom_validation",
                                                  current_schema)

          JSON::Validator.validation_error(err)
        end
      end
    end
  end

  JSON::Validator.register_validator(self.new)
end
