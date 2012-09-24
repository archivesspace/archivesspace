
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

        if data.has_key?(property)
          schema = JSON::Schema.new(property_schema, current_schema.uri,validator)
          fragments << property
          schema.validate(data[property], fragments,options)
          fragments.pop
        end
      end
    end
  end

end


class ArchivesSpaceTypeAttribute < JSON::Schema::TypeAttribute
  extend JSONModel


  def self.validate(current_schema, data, fragments, validator, options = {})

    types = current_schema.schema['type']

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

          top_errors = validation_errors
          ::JSON::Validator.clear_errors

          JSONModel(model).from_hash(data, false)

          nested_errors = validation_errors

          nested_errors.each do |validation_error|
            # Add the fragment path to each nested exception to make them
            # findable from the root of the top-level json document.
            validation_error.fragments = fragments + validation_error.fragments
          end

          # Push them all back
          (top_errors + nested_errors).each do |error|
            ::JSON::Validator.validation_error(error)
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


class ArchivesSpaceSchema < JSON::Schema::Validator
  def initialize
    super
    extend_schema_definition("http://json-schema.org/draft-03/schema#")
    @attributes["type"] = ArchivesSpaceTypeAttribute
    @attributes["properties"] = IfMissingAttribute
    @uri = URI.parse("http://www.archivesspace.org/archivesspace.json")
  end


  def validate(current_schema, data, fragments, options = {})
    if current_schema.schema.has_key?("validations")
      current_schema.schema["validations"].each do |name|
        errors = JSONModel::custom_validations[name].call(data)

        errors.each do |field, msg|
          err = JSON::Schema::ValidationError.new("Validation failed for '#{field}': #{msg}",
                                                  fragments,
                                                  "custom_validation",
                                                  current_schema)
          JSON::Validator.validation_error(err)
        end
      end
    end

    super
  end

  JSON::Validator.register_validator(self.new)
end
