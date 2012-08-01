require 'json-schema'


module JSONModel

  @@schema = {}
  @@types = {}
  @@models = {}


  class ValidationException < StandardError
    attr_accessor :invalid_object
    attr_accessor :errors

    def initialize(opts)
      @invalid_object = opts[:invalid_object]
      @errors = opts[:errors]
    end

    def to_s
      "#<:ValidationException: #{@errors.inspect}>"
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


  def self.create_model_for(type, schema)

    cls = Class.new do

      if Module.const_defined?(:Rails)
        require_relative 'jsonmodel_rails'

        include ActiveModel::Validations
        include ActiveModel::Conversion
        include JSONModel::Rails
        extend ActiveModel::Naming
      end


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


      def initialize(params, warnings = [])
        @data = params
        @warnings = warnings

        self.class.define_accessors(@data.keys)
      end


      def _warnings
        self.class.validate(@data)
      end


      def self.record_type
        self.lookup(@@types)
      end


      # For a reference like "/collections/123", return 123.
      def get_reference_id(reference)
        if @data[reference] =~ /\/([0-9]+)$/
          return $1.to_i
        else
          return nil
        end
      end


      def update(params)
        self.class.validate(@data.merge(params))
        @data = @data.merge(params)
      end


      def to_s
        "#<:#{self.class.record_type} record>"
      end


      def to_hash
        cleaned = self.class.drop_unknown_properties(@data)
        self.class.validate(cleaned)

        cleaned
      end


      def to_json
        JSON(self.to_hash)
      end


      def self.lookup(hash)
        my_true_self = self.ancestors.find {|cls| hash[cls]}

        if my_true_self
          return hash[my_true_self]
        end

        return nil
      end


      def self.drop_unknown_properties(params)
        schema = self.lookup(@@schema)

        result = {}

        params.each do |k, v|
          k = k.to_s

          if schema["properties"].has_key?(k)
            if schema["properties"][k]["type"] == "object"
              result[k] = self.drop_unknown_properties(v, schema["properties"][k])
            else
              result[k] = v
            end
          end
        end

        result
      end


      def self.parse_schema_messages(messages)
        errors = {}
        warnings = {}

        messages.each do |message|

          if (message[:failed_attribute] == 'Properties' and
              message[:message] =~ /.*did not contain a required property of '(.*?)'.*/)

            warnings[$1] = ["Property is required but was missing"]

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


      def self.validate(hash)
        messages = JSON::Validator.fully_validate(self.lookup(@@schema),
                                                  self.drop_unknown_properties(hash),
                                                  :errors_as_objects => true)

        exceptions = self.parse_schema_messages(messages)

        if not exceptions[:errors].empty?
          raise ValidationException.new(:invalid_object => self.new(hash),
                                        :warnings => exceptions[:warnings],
                                        :errors => exceptions[:errors])
        end

        exceptions[:warnings]
      end


      def self.from_hash(hash)
        validate(hash)

        # Note that I don't use the cleaned version here.  We want to keep
        # around the original extra stuff (and provide accessors for then
        # too), but just want to strip them out when converting back to JSON
        self.new(hash)
      end


      def self.from_sequel(obj)
        self.from_hash(obj.values.reject {|k, v| v.nil?})
      end


      def self.from_json(s)
        self.from_hash(JSON(s))
      end

    end


    cls.define_accessors(schema['properties'].keys)

    @@types[cls] = type
    @@schema[cls] = schema
    @@models[type] = cls
  end



  # Load all JSON schemas from the schemas subdirectory
  # Create a model class for each one.
  Dir.glob(File.join(File.dirname(__FILE__),
                     "schemas",
                     "*.rb")).each do |schema|
    schema_name = File.basename(schema, ".rb")

    old_verbose = $VERBOSE
    $VERBOSE = nil
    entry = eval(File.open(schema).read)
    $VERBOSE = old_verbose

    self.create_model_for(schema_name, entry[:schema])
  end

end
