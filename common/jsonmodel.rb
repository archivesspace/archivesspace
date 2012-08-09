require 'json-schema'


module JSONModel

  @@schema = {}
  @@types = {}
  @@models = {}
  @@required_fields = {}

  @@protected_fields = []

  @@strict_mode = false
  @@client_mode = false


  def strict_mode(val)
    @@strict_mode = val
  end


  class ValidationException < StandardError
    attr_accessor :invalid_object
    attr_accessor :errors
    attr_accessor :warnings

    def initialize(opts)
      @invalid_object = opts[:invalid_object]
      @errors = opts[:errors]
      @warnings = opts[:warnings]
    end

    def to_s
      "#<:ValidationException: #{{:errors => @errors, :warnings => @warnings}.inspect}>"
    end
  end


  def JSONModel(source)

    # Checks if a model exists first; returns the model class
    # if it exists; returns false if it doesn't exist.
    if @@models.has_key?(source.to_s)
      @@models[source.to_s]
    else
      false
    end
  end


  # Parse a URI reference like /repositories/123/archival_objects/500 into
  # {:id => 500, :type => :archival_object}
  def self.parse_reference(reference, opts = {})
    @@models.each do |type, model|
      id = model.id_for(reference, opts, true)
      if id
        return {:id => id, :type => type}
      end
    end

    nil
  end


  # Preprocess the schema to support ArchivesSpace extensions
  def self.preprocess_schema(type, schema, path = [])
    @@required_fields[type] ||= {}

    if schema["type"] == "object"
      schema["properties"].each do |property, defn|
        if defn.has_key?("ifmissing")
          if ["error", "warn"].include?(defn["ifmissing"])
            defn["required"] = true

            path_s = "#/" + path.join("/")
            @@required_fields[type][path_s] ||= {}

            @@required_fields[type][path_s][property] = defn["ifmissing"]
          else
            defn["required"] = false
          end
        end

        self.preprocess_schema(type, defn, path + [property])
      end
    end
  end


  # Create and return a new JSONModel class called 'type', based on the
  # JSONSchema 'schema'
  def self.create_model_for(type, schema)

    preprocess_schema(type, schema)

    cls = Class.new do

      # In client mode, mix in some extra convenience methods for querying the
      # ArchivesSpace backend service via HTTP.
      if @@client_mode
        require_relative 'jsonmodel_client'
        include JSONModel::Client
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
              @data[attribute] = value
            end
          end
        end
      end


      def self.to_s
        "JSONModel(:#{self.record_type})"
      end


      # Return the type of this JSONModel class (a keyword like
      # :archival_object)
      def self.record_type
        self.lookup(@@types)
      end


      # Return the JSON schema that defines this JSONModel class
      def self.schema
        self.lookup(@@schema)
      end


      # Find the entry for this JSONModel class in the supplied 'hash'.
      def self.lookup(hash)
        my_true_self = self.ancestors.find {|cls| hash[cls]}

        if my_true_self
          return hash[my_true_self]
        end

        return nil
      end


      # Given a (potentially nested) 'hash', remove any properties that don't
      # appear in the JSON schema defining this JSONModel.
      def self.drop_unknown_properties(hash, schema = nil)
        if schema.nil?
          self.drop_unknown_properties(hash, self.schema)
        else

          result = {}

          if schema["$ref"] == "#"
            # A recursive schema.  Back to the beginning.
            schema = self.schema
          end

          hash.each do |k, v|
            k = k.to_s

            if schema["properties"].has_key?(k)
              if schema["properties"][k]["type"] == "object"
                result[k] = self.drop_unknown_properties(v, schema["properties"][k])
              elsif schema["properties"][k]["type"] == "array"
                result[k] = v.collect {|elt| self.drop_unknown_properties(elt, schema["properties"][k]["items"])}
              elsif v and v != ""
                result[k] = v
              end
            end
          end

          result
        end
      end


      # Given a list of error messages produced by JSON schema validation, parse
      # them into a structured format like:
      #
      # {
      #   :errors => {:attr1 => "(What was wrong with attr1)"},
      #   :warnings => {:attr2 => "(attr2 not quite right either)"}
      # }
      def self.parse_schema_messages(messages)
        errors = {}
        warnings = {}

        messages.each do |message|

          if (message[:failed_attribute] == 'Properties' and
              message[:message] =~ /The property '(.*?)' did not contain a required property of '(.*?)'.*/)

            (path, property) = [$1, $2]

            exception_type = @@required_fields[self.record_type].fetch(path, {})[property]

            if exception_type == "error"
              errors[property] = ["Property is required but was missing"]
            else
              warnings[property] = ["Property is required but was missing"]
            end

          elsif (message[:failed_attribute] == 'Pattern' and
                 message[:message] =~ /The property '#\/(.*?)' did not match the regex '(.*?)' in schema/)

            errors[$1] = ["Did not match regular expression: #{$2}"]

          elsif (message[:failed_attribute] == 'MinLength' and
                 message[:message] =~ /The property '#\/(.*?)' was not of a minimum string length of ([0-9]+) in schema/)

            errors[$1] = ["Must be at least #{$2} characters"]

          elsif (message[:failed_attribute] == 'Type' and
                 message[:message] =~ /The property '#\/(.*?)' of type (.*?) did not match the following type: (.*?) in schema/)

            errors[$1] = ["Must be a #{$3} (you provided a #{$2})"]

          else
            puts "Failed to find a matching parse rule for: #{message}"
            errors[:unknown] = ["Failed to find a matching parse rule for: #{message}"]
          end

        end

        {
          :errors => errors,
          :warnings => warnings,
        }
      end


      # Validate the supplied hash using the JSON schema for this model.  Raise
      # a ValidationException if there are any fatal validation problems, or if
      # strict mode is enabled and warnings were produced.
      def self.validate(hash, raise_errors = true)
        messages = JSON::Validator.fully_validate(self.schema,
                                                  self.drop_unknown_properties(hash),
                                                  :errors_as_objects => true)

        exceptions = self.parse_schema_messages(messages)

        if raise_errors and not exceptions[:errors].empty? or (@@strict_mode and not exceptions[:warnings].empty?)
          raise ValidationException.new(:invalid_object => self.new(hash),
                                        :warnings => exceptions[:warnings],
                                        :errors => exceptions[:errors])
        end

        exceptions
      end


      # Create an instance of this JSONModel from the data contained in 'hash'.
      def self.from_hash(hash, raise_errors = true)
        validate(hash, raise_errors)

        # Note that I don't use the cleaned version here.  We want to keep
        # around the original extra stuff (and provide accessors for them
        # too), but just want to strip them out when converting back to JSON
        self.new(hash)
      end


      # Create an instance of this JSONModel from a JSON string.
      def self.from_json(s, raise_errors = true)
        self.from_hash(JSON(s), raise_errors)
      end


      # Given a URI like /repositories/:repo_id/something/:somevar, and a hash
      # containing keys and replacement strings, return a URI with the values
      # substituted in for their placeholders.
      #
      # This looks for a 'get_globals' defined on the current class for
      # additional key/value pairs to substitute, allowing mix ins to add their
      # own.
      def self.substitute_parameters(uri, opts = {})
        if self.respond_to? :get_globals
          # Used by the jsonmodel_client to pass through implicit parameters
          opts = self.get_globals.merge(opts)
        end

        opts.each do |k, v|
          uri = uri.gsub(":#{k}", v.to_s)
        end

        uri
      end


      # Given a numeric internal ID and additional options produce a URI reference.
      # For example:
      #
      #     JSONModel(:archival_object).uri_for(500, :repo_id => 123)
      #
      #  might yield "/repositories/123/archival_objects/500"
      #
      def self.uri_for(id = nil, opts = {})
        uri = self.schema['uri']

        if not id.nil?
          uri += "/#{id}"
        end

        if id
          opts["id"] = id
        end

        self.substitute_parameters(uri, opts)
      end


      # The inverse of uri_for:
      #
      #     JSONModel(:archival_object).id_for("/repositories/123/archival_objects/500", :repo_id => 123)
      #
      #  might yield 500
      #
      def self.id_for(uri, opts = {}, noerror = false)
        pattern = self.schema['uri'];
        pattern = pattern.gsub(/\/:[a-zA-Z_]+\//, '/[^/ ]+/')

        if uri =~ /#{pattern}\/([0-9]+)$/
          return $1.to_i
        else
          if noerror
            nil
          else
            raise "Couldn't make an ID out of URI: #{uri}"
          end
        end
      end



      def initialize(params = {}, warnings = [])
        @data = params
        @warnings = warnings

        self.class.define_accessors(@data.keys)
      end


      def [](key)
        @data[key.to_s]
      end


      # Validate the current JSONModel instance and return a list of exceptions
      # produced.
      def _exceptions
        exceptions = {}
        if not @always_valid
          exceptions = self.class.validate(@data, false).reject{|k, v| v.empty?}
        end

        if @errors
          exceptions[:errors] = (exceptions[:errors] or {}).merge(@errors)
        end

        exceptions
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
        replace(@data.merge(params))
      end


      # Replace the values of the current JSONModel instance with the contents
      # of 'params', validating before accepting the replacement.
      def replace(params)
        @@protected_fields.each do |field|
          params[field] = @data[field]
        end

        @data = params
      end


      def to_s
        "#<JSONModel(:#{self.class.record_type}) #{@data.inspect}>"
      end


      # Produce a (possibly nested) hash from the values of this JSONModel.  Any
      # values that don't appear in the JSON schema will not appear in the
      # result.
      def to_hash
        cleaned = self.class.drop_unknown_properties(@data)
        self.class.validate(cleaned)

        cleaned
      end


      # Produce a JSON string from the values of this JSONModel.  Any values
      # that don't appear in the JSON schema will not appear in the result.
      def to_json
        JSON(self.to_hash)
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
    end



    cls.define_accessors(schema['properties'].keys)

    @@types[cls] = type
    @@schema[cls] = schema
    @@models[type] = cls
  end


  def self.destroy_model(type)
    type = type.to_s

    cls = @@models[type]

    if cls
      @@types.delete(cls)
      @@schema.delete(cls)
      @@models.delete(type)
    end
  end



  def self.init_args
    @@init_args
  end


  def self.init(opts = {})

    if opts.has_key?(:client_mode)
      @@client_mode = true
    end

    if opts.has_key?(:strict_mode)
      @@strict_mode = true
    end

    @@init_args = opts

    # Load all JSON schemas from the schemas subdirectory
    # Create a model class for each one.
    Dir.glob(File.join(File.dirname(__FILE__),
                       "schemas",
                       "*.rb")).sort.each do |schema|
      schema_name = File.basename(schema, ".rb")

      old_verbose = $VERBOSE
      $VERBOSE = nil
      entry = eval(File.open(schema).read)
      $VERBOSE = old_verbose

      self.create_model_for(schema_name, entry[:schema])
    end

    true
  end

end
