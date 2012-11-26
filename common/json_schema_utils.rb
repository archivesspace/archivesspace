module JSONSchemaUtils

  def self.fragment_join(fragment, property = nil)
    fragment = fragment.gsub(/^#\//, "")
    property = property.gsub(/^#\//, "") if property

    if property and fragment != "" and fragment !~ /\/$/
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
       :failed_attribute => ['Properties', 'IfMissing'],
       :pattern => /([A-Z]+: )?The property '.*?' did not contain a required property of '(.*?)'.*/,
       :do => ->(msgs, message, path, type, property) {

         schema = ::JSON::Validator.schemas[message[:schema].to_s].schema

         if type and type =~ /ERROR/
           msgs[:errors][fragment_join(path, property)] = ["Property is required but was missing"]
         else
           msgs[:warnings][fragment_join(path, property)] = ["Property was missing"]
         end
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
       :failed_attribute => ['MinItems'],
       :pattern => /The property '#\/.*?' did not contain a minimum number of items ([0-9]+) in schema/,
       :do => ->(msgs, message, path, items) {
         msgs[:errors][fragment_join(path)] = ["The '#{path}' array needs at least #{items} elements"]
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
       :failed_attribute => ['Type', 'ArchivesSpaceType'],
       :pattern => /The property '#\/.*?' of type (.*?) did not match the following type: (.*?) in schema/,
       :do => ->(msgs, message, path, actual_type, desired_type) {
         if actual_type !~ /JSONModel/ || message[:failed_attribute] == 'ArchivesSpaceType'
           # We'll skip JSONModels because the specific problem with the
           # document will have already been listed separately.
           msgs[:errors][fragment_join(path)] = ["Must be a #{desired_type} (you provided a #{actual_type})"]
         end

       }
     },

     {
       :failed_attribute => ['Type', 'ArchivesSpaceType'],
       :pattern => /The property '#\/.*?' of type (.*?) did not match one or more of the following types:.*in schema/,
       :do => ->(msgs, message, path, actual_type) {

         types = []

         message[:errors].each do |sub_msg|
           if sub_msg[:message] =~ /did not match the following type: (.*?) in schema/
             types << $1
           end
         end

         if message[:failed_attribute] == 'ArchivesSpaceType'
           msgs[:errors][fragment_join(path)] = ["Type must be one of: #{types.inspect}"]
         end
       }
     },


     {
       :failed_attribute => ['custom_validation'],
       :pattern => /Validation failed for '(.*?)': (.*?) in schema /,
       :do => ->(msgs, message, path, property, msg) {
         msgs[:errors][fragment_join(path, property)] = [msg]
       }
     },

     # Catch all
     {
       :failed_attribute => nil,
       :pattern => /^(.*)$/,
       :do => ->(msgs, message, path, msg) {
         msgs[:errors][:unknown] = [msg]
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
    }

    messages.each do |message|

      SCHEMA_PARSE_RULES.each do |rule|
        if (rule[:failed_attribute].nil? || rule[:failed_attribute].include?(message[:failed_attribute])) and
            message[:message] =~ rule[:pattern]
          puts "MSG #{message.inspect}"
          rule[:do].call(msgs, message, message[:fragment],
                         *message[:message].scan(rule[:pattern]).flatten)

          break
        end
      end

    end

    msgs
  end

end
