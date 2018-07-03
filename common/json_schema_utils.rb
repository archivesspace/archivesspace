module JSONSchemaUtils

  def self.fragment_join(fragment, property = nil)
    fragment = fragment.gsub(/^#\//, "")
    property = property.gsub(/^#\//, "") if property

    if property && fragment != "" && fragment !~ /\/$/
      fragment = "#{fragment}/"
    end

    "#{fragment}#{property}"
  end


  def self.schema_path_lookup(schema, path)
    if path.is_a? String
      return self.schema_path_lookup(schema, path.split("/"))
    end

    if schema.has_key?('properties')
      schema = schema['properties']
    end

    if path.length == 1
      schema[path.first]
    else
      if schema[path.first]
        self.schema_path_lookup(schema[path.first], path.drop(1))
      else
        nil
      end
    end
  end



  SCHEMA_PARSE_RULES =
    [
     {
       :failed_attribute => ['Properties', 'IfMissing', 'ArchivesSpaceSubType'],
       :pattern => /([A-Z]+: )?The property '.*?' did not contain a required property of '(.*?)'.*/,
       :do => ->(msgs, message, path, type, property) {
         if type && type =~ /ERROR/
           msgs[:errors][fragment_join(path, property)] = ["Property is required but was missing"]
         else
           msgs[:warnings][fragment_join(path, property)] = ["Property was missing"]
         end
       }
     },

     {
       :failed_attribute => ['ArchivesSpaceType'],
       :pattern => /The property '#(.*?)' was not a well-formed date/,
       :do => ->(msgs, message, path, property) {
         msgs[:errors][fragment_join(path)] = ["Not a valid date"]
       }
     },

     {
       :failed_attribute => ['Pattern'],
       :pattern => /The property '#\/.*?' did not match the regex '(.*?)' in schema/,
       :do => ->(msgs, message, path, regexp) {
         msgs[:errors][fragment_join(path)] = ["Did not match regular expression: #{regexp}"]
       }
     },

     {
       :failed_attribute => ['MinLength'],
       :pattern => /The property '#\/.*?' was not of a minimum string length of ([0-9]+) in schema/,
       :do => ->(msgs, message, path, length) {
         msgs[:errors][fragment_join(path)] = ["Must be at least #{length} characters"]
       }
     },

     {
       :failed_attribute => ['MaxLength'],
       :pattern => /The property '#\/.*?' was not of a maximum string length of ([0-9]+) in schema/,
       :do => ->(msgs, message, path, length) {
         msgs[:errors][fragment_join(path)] = ["Must be #{length} characters or fewer"]
       }
     },

     {
       :failed_attribute => ['MinItems'],
       :pattern => /The property '#\/.*?' did not contain a minimum number of items ([0-9]+) in schema/,
       :do => ->(msgs, message, path, items) {
         msgs[:errors][fragment_join(path)] = ["At least #{items} item(s) is required"]
       }
     },

     {
       :failed_attribute => ['Enum'],
       :pattern => /The property '#\/.*?' value "(.*?)" .*values: (.*) in schema/,
       :do => ->(msgs, message, path, invalid, valid_set) {
         msgs[:errors][fragment_join(path)] = ["Invalid value '#{invalid}'.  Must be one of: #{valid_set}"]
       }
     },
     
     {
       :failed_attribute => ['ArchivesSpaceDynamicEnum'],
       :pattern => /The property '#\/.*?' value "(.*?)" .*values: (.*) in schema/,
       :do => ->(msgs, message, path, invalid, valid_set) {
         msgs[:attribute_types][fragment_join(path)] = 'ArchivesSpaceDynamicEnum'
         msgs[:errors][fragment_join(path)] = ["Invalid value '#{invalid}'.  Must be one of: #{valid_set}"]
       }
     },
     {
       :failed_attribute => ['ArchivesSpaceReadOnlyDynamicEnum'],
       :pattern => /The property '#\/.*?' value "(.*?)" .*values: (.*) in schema/,
       :do => ->(msgs, message, path, invalid, valid_set) {
         msgs[:attribute_types][fragment_join(path)] = 'ArchivesSpaceReadOnlyDynamicEnum'
         msgs[:errors][fragment_join(path)] = ["Protected read-only list #{path}. Invalid value '#{invalid}'.  Must be one of: #{valid_set}"]
       }
     },

     {
       :failed_attribute => ['Type', 'ArchivesSpaceType'],
       :pattern => /The property '#\/.*?' of type (.*?) did not match the following type: (.*?) in schema/,
       :do => ->(msgs, message, path, actual_type, desired_type) {
         if actual_type !~ /JSONModel/ || message[:failed_attribute] == 'ArchivesSpaceType'
           # We'll skip JSONModels because the specific problem with the
           # document will have already been listed separately.

           msgs[:state][fragment_join(path)] ||= []
           msgs[:state][fragment_join(path)] << desired_type

           if msgs[:state][fragment_join(path)].length == 1
             msgs[:errors][fragment_join(path)] = ["Must be a #{desired_type} (you provided a #{actual_type})"]
             # a little better messages for malformed uri 
             if desired_type =~ /uri$/
              msgs[:errors][fragment_join(path)].first << " (malformed or invalid uri? check if referenced object exists.)"
             end
           else
             msgs[:errors][fragment_join(path)] = ["Must be one of: #{msgs[:state][fragment_join(path)].join (", ")} (you provided a #{actual_type})"]
           end
         end

       }
     },

     {
       :failed_attribute => ['custom_validation'],
       :pattern => /Validation failed for '(.*?)': (.*?) in schema /,
       :do => ->(msgs, message, path, property, msg) {
         property = (property && !property.empty?) ? property : nil
         msgs[:errors][fragment_join(path, property)] = [msg]
       }
     },

     {
       :failed_attribute => ['custom_validation'],
       :pattern => /Warning generated for '(.*?)': (.*?) in schema /,
       :do => ->(msgs, message, path, property, msg) {
         msgs[:warnings][fragment_join(path, property)] = [msg]
       }
     },

     {
       :failed_attribute => ['custom_validation'],
       :pattern => /Validation error code: (.*?) in schema /,
       :do => ->(msgs, message, path, error_code) {
         msgs[:errors]['coded_errors'] = [error_code]
       }
     },


     # Catch all
     {
       :failed_attribute => nil,
       :pattern => /^(.*)$/,
       :do => ->(msgs, message, path, msg) {
         msgs[:errors]['unknown'] = [msg]
       }
     }
    ]


  # For a given error, find its list of sub errors.
  def self.extract_suberrors(errors)
    errors = Array[errors].flatten

    result = errors.map do |error|
      if !error[:errors]
        error
      else
        self.extract_suberrors(error[:errors])
      end
    end

    result.flatten
  end



  # Given a list of error messages produced by JSON schema validation, parse
  # them into a structured format like:
  #
  # {
  #   :errors => {:attr1 => "(What was wrong with attr1)"},
  #   :warnings => {:attr2 => "(attr2 not quite right either)"}
  # }
  def self.parse_schema_messages(messages, validator)

    messages = self.extract_suberrors(messages)

    msgs = {
      :errors => {},
      :warnings => {},
      # to lookup e.g., msgs[:attribute_types]['extents/0/extent_type'] => 'ArchivesSpaceDynamicEnum'
      :attribute_types => {},
      :state => {}              # give the parse rules somewhere to store useful state for a run
    }

    messages.each do |message|

      SCHEMA_PARSE_RULES.each do |rule|
        if (rule[:failed_attribute].nil? || rule[:failed_attribute].include?(message[:failed_attribute])) and
            message[:message] =~ rule[:pattern]
          rule[:do].call(msgs, message, message[:fragment],
                         *message[:message].scan(rule[:pattern]).flatten)

          break
        end
      end

    end

    msgs.delete(:state)
    msgs
  end


  # Given a hash representing a record tree, map across the hash and this
  # model's schema in lockstep.
  #
  # Each proc in the 'transformations' array is called with the current node
  # in the record tree as its first argument, and the part of the schema
  # that corresponds to it.  Whatever the proc returns is used to replace
  # the node in the record tree.
  #
  def self.map_hash_with_schema(record, schema, transformations = [])
    return record if not record.is_a?(Hash)

    if schema.is_a?(String)
      schema = resolve_schema_reference(schema)
    end

    # Sometimes a schema won't specify anything other than the required type
    # (like {'type' => 'object'}).  If there's nothing more to check, we're
    # done.
    return record if !schema.has_key?("properties")


    # Apply transformations to the current level of the tree
    transformations.each do |transform|
      record = transform.call(record, schema)
    end

    # Now figure out how to traverse the remainder of the tree...
    result = {}

    record.each do |k, v|
      k = k.to_s
      properties = schema['properties']

      if properties.has_key?(k) && (properties[k]["type"] == "object")
        result[k] = self.map_hash_with_schema(v, properties[k], transformations)

      elsif v.is_a?(Array) && properties.has_key?(k) && (properties[k]["type"] == "array")

        # Arrays are tricky because they can either consist of a single type, or
        # a number of different types.

        if properties[k]["items"]["type"].is_a?(Array)
          result[k] = v.map {|elt|

            if elt.is_a?(Hash)
              next_schema = determine_schema_for(elt, properties[k]["items"]["type"])
              self.map_hash_with_schema(elt, next_schema, transformations)
            elsif elt.is_a?(Array)
              raise "Nested arrays aren't supported here (yet)"
            else
              elt
            end
          }

        # The array contains a single type of object
        elsif properties[k]["items"]["type"] === "object"
          result[k] = v.map {|elt| self.map_hash_with_schema(elt, properties[k]["items"], transformations)}
        else
          # Just one valid type
          result[k] = v.map {|elt| self.map_hash_with_schema(elt, properties[k]["items"]["type"], transformations)}
        end

      elsif (v.is_a?(Hash) || v.is_a?(Array)) && (properties.has_key?(k) && properties[k]["type"].is_a?(Array))
        # Multiple possible types for this single value

        results = (v.is_a?(Array) ? v : [v]).map {|elt|
          next_schema = determine_schema_for(elt, properties[k]["type"])
          self.map_hash_with_schema(elt, next_schema, transformations)
        }

        result[k] = v.is_a?(Array) ? results : results[0]

      elsif properties.has_key?(k) && JSONModel.parse_jsonmodel_ref(properties[k]["type"])
        result[k] = self.map_hash_with_schema(v, properties[k]["type"], transformations)
      else
        result[k] = v
      end
    end

    result
  end

  def self.blank?(obj)
    obj.nil? || obj == '' || obj == {}
  end

  def self.drop_empty_elements(obj)
    if obj.is_a?(Hash)
      Hash[obj.map do |k, v|
             v = drop_empty_elements(v)
             [k, v] unless blank?(v)
           end.compact]
    elsif obj.is_a?(Array)
      obj.map { |elt| drop_empty_elements(elt) }.reject { |elt| blank?(elt) }
    else
      obj
    end
  end

  # Drop any keys from 'hash' that aren't defined in the JSON schema.
  #
  # If drop_readonly is true, also drop any values where the schema has
  # 'readonly' set to true.  These values are produced by the system for the
  # client, but are not part of the data model.
  #
  def self.drop_unknown_properties(hash, schema, drop_readonly = false)
    fn = proc do |hash, schema|
      result = {}

      hash.each do |k, v|
        if schema["properties"].has_key?(k.to_s) && (!drop_readonly || !schema["properties"][k.to_s]["readonly"])
          result[k] = v
        end
      end

      result
    end

    hash = drop_empty_elements(hash)
    map_hash_with_schema(hash, schema, [fn])
  end


  def self.apply_schema_defaults(hash, schema)
    fn = proc do |hash, schema|
      result = hash.clone

      schema["properties"].each do |property, definition|

        if definition.has_key?("default") && !hash.has_key?(property.to_s) && !hash.has_key?(property.intern)
          result[property] = definition["default"]
        elsif definition['type'] == 'array' && !hash.has_key?(property.to_s) && !hash.has_key?(property.intern)
          # Array values that weren't provided default to empty
          result[property] = []
        end

      end

      result
    end

    map_hash_with_schema(hash, schema, [fn])
  end


  private

  def self.resolve_schema_reference(schema_reference)
    # This should be a reference to a different JSONModel type.  Resolve it
    # and return its schema.
    ref = JSONModel.parse_jsonmodel_ref(schema_reference)
    raise "Invalid schema given: #{schema_reference}" if !ref

    JSONModel.JSONModel(ref[0]).schema
  end


  def self.determine_schema_for(elt, possible_schemas)
    # A number of different types.  Match them up based on the value of the 'jsonmodel_type' property
    schema_types = possible_schemas.map {|schema| schema.is_a?(Hash) ? schema["type"] : schema}

    jsonmodel_type = elt["jsonmodel_type"] || elt[:jsonmodel_type]

    if !jsonmodel_type
      raise JSONModel::ValidationException.new(:errors => {"record" => ["Can't unambiguously match #{elt.inspect} against schema types: #{schema_types.inspect}. " +
                                                             "Resolve this by adding a 'jsonmodel_type' property to #{elt.inspect}"]})
    end

    next_schema = schema_types.find {|type|
      (type.is_a?(String) && type.include?("JSONModel(:#{jsonmodel_type})")) ||
      (type.is_a?(Hash) && type["jsonmodel_type"] === jsonmodel_type)
    }

    if next_schema.nil?
      raise "Couldn't determine type of '#{elt.inspect}'.  Must be one of: #{schema_types.inspect}"
    end

    next_schema
  end


end
