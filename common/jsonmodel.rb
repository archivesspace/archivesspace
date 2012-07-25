# -------------------------------------------------------------------------------
# Parts of this file are borrowed from Dondoh's Faux model object.
#
#  Created: by dondoh
#  Website: http://dondoh.tumblr.com/post/4142258573/formtastic-without-activerecord
#  Licence: Under the following conditions:
#
#            * Attribution -- you must attribute the work to me (a comment in
#              the code is sufficient, although I would also accept a role in
#              the movie adaptation)
#
#            * Share alike -- if you alter, transform, or build upon this work,
#              you may distribute the work only under the same or similar
#              license to this one.
#
# -------------------------------------------------------------------------------

require 'json-schema'
require_relative 'idutils'

module JSONModel

  # Load all JSON schemas from the schemas subdirectory
  $schema = {}
  $hooks = {}

  Dir.glob(File.join(File.dirname(__FILE__),
                     "schemas",
                     "*.rb")).each do |schema|
    schema_name = File.basename(schema, ".rb")

    old_verbose = $VERBOSE
    $VERBOSE = nil
    entry = eval(File.open(schema).read)
    $VERBOSE = old_verbose

    $schema[:"#{schema_name}"] = entry[:schema]
    $hooks[:"#{schema_name}"] = entry[:hooks]
  end


  class JSONValidationException < StandardError
    attr_accessor :invalid_object
    attr_accessor :errors

    def initialize(opts)
      @invalid_object = opts[:invalid_object]
      @errors = opts[:errors]
    end
  end


  def JSONModel(source)
    cls = Class.new do

      begin
        include ActiveModel::Validations
        include ActiveModel::Conversion
        extend  ActiveModel::Naming
      rescue NameError
        # This is normal when loading this library outside of a Rails
        # environment, and we don't need this extra stuff for non-Rails uses
        # anyway.
      end

      class << self
        attr_accessor :types
      end
      self.types = {}


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


      def persisted?
        false
      end


      def column_for_attribute(attr)
        FauxColumnInfo.new(self.class.types[attr])
      end


      class FauxColumnInfo
        attr_accessor :type, :limit

        def initialize(type_info)
          type_info ||= :string
          case
          when  type_info.instance_of?(Hash), type_info.instance_of?(OpenStruct)
            self.type = type_info[:type].to_sym
            self.limit = type_info[:limit]
          else
            self.type = type_info.to_sym
            self.limit = nil
          end
        end
      end


      def to_s
        "#<:#{@@type} record>"
      end


      def to_hash
        self.class.drop_extra_properties(@data, @@schema)
      end


      def to_json
        JSON(self.to_hash)
      end


      def self.drop_extra_properties(params, schema)
        result = {}

        params.each do |k, v|
          k = k.to_s

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
        if $hooks[@@type] and $hooks[@@type][:from_hash]
          params = $hooks[@@type][:from_hash].call(params)
        end

        cleaned = self.drop_extra_properties(params, @@schema)

        errors = JSON::Validator.fully_validate(@@schema, cleaned,
                                                :errors_as_objects => true)

        if errors.empty?
          # Note that I don't use the cleaned version here.  We want to keep
          # around the original extra stuff (and provide accessors for then
          # too), but just want to strip them out when converting back to JSON
          self.new(params)
        else
          raise JSONValidationException.new(:invalid_object => self.new(params),
                                            :errors => errors)
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
