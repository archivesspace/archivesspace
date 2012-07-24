module JSONModel

  # Load all JSON schemas from the schemas subdirectory
  $schema = {}
  Dir.glob(File.join(File.dirname(__FILE__),
                     "schemas",
                     "*.rb")).each do |schema|
    schema_name = File.basename(schema, ".rb")
    $schema[:"#{schema_name}"] = eval(File.open(schema).read)
  end


  def JSONModel(source)
    cls = Class.new do

      def self.define_accessors(attributes)
        attributes.each do |attribute|

          define_method "#{attribute}" do
            @data[attribute]
          end

          define_method "#{attribute}=" do |value|
            @data[attribute] = value
          end
        end
      end

      def self.set_schema(type, schema)
        @@type = type
        @@schema = schema

        # Define accessors
        self.define_accessors(@@schema['properties'].keys)
      end


      def initialize(params)
        @data = params

        self.class.define_accessors(@data.keys)
      end


      def to_s
        "#<:#{@@type} record>"
      end


      def to_json
        JSON(self.class.drop_extra_properties(@data, @@schema))
      end


      def self.drop_extra_properties(params, schema)
        result = {}

        params.each do |k, v|
          if schema["properties"].has_key?(k)
            if schema["properties"][k]["type"] == "object"
              result[k] = self.drop_extra_properties(v, schema["properties"][k])
            else
              result[k] = v
            end
          end
        end

        result
      end


      def self.from_hash(params)
        cleaned = self.drop_extra_properties(params, @@schema)

        errors = JSON::Validator.fully_validate(@@schema, cleaned,
                                                :errors_as_objects => true)

        if errors.empty?
          # Note that I don't use the cleaned version here.  We want to keep
          # around the original extra stuff (and provide accessors for then
          # too), but just want to strip them out when converting back to JSON
          self.new(params)
        else
          raise Exception.new("Validation error.  Do something clever here!: #{errors.inspect}")
        end
      end


      def self.from_json(s)
        self.from_hash(JSON(s))
      end

    end


    if not $schema[source]
      raise Exception.new("Unknown data type: #{source}")
    end

    cls.set_schema(source, $schema[source])
    cls
  end


end
