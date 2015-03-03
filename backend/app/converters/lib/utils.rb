require 'securerandom'

module ASpaceImport
  module Utils

    # Fake an ID to create URIs
    def self.mint_id
      "import_#{SecureRandom.uuid}"
    end


    def self.get_property_type(property_def)
      # subrecord slots taking more than one type
      if property_def['type'].is_a? Array
        if ((property_def['type'] | ["integer", "string"]) - (property_def['type'] & ["integer", "string"])).empty?
          return [:string_or_integer, nil]
        elsif property_def['type'].reject {|t| t['type'].match(/object$/)}.length != 0
          raise ASpaceImportException.new(:property_def => property_def)
        end

        return [:record_inline, property_def['type'].map {|t| t['type'].scan(/:([a-zA-Z_]*)/)[0][0] }]
      end

      # dynamic enums

      if property_def['type'] == 'string' && property_def.has_key?('dynamic_enum')
        return [:dynamic_enum, nil]
      end

      # all other cases

      case property_def['type']

      when 'boolean'
        [:boolean, nil]

      when 'integer'
        [:integer, nil]

      when 'date'
        [:string, nil]

      when 'string'
        [:string, nil]

      when 'object'
        if property_def['subtype'] == 'ref'
          [:record_ref, ref_type_list(property_def['properties']['ref']['type'])]
        else
          [:object_inline, nil] # e.g., resource - external_id
        end

      when 'array'
        arr = get_property_type(property_def['items'])
        [(arr[0].to_s + '_list').to_sym, arr[1]]

      when /^JSONModel\(:([a-z_]*)\)\s(uri)$/
        [:record_uri, [$1]]

      when /^JSONModel\(:([a-z_]*)\)\s(uri_or_object)$/
        [:record_uri_or_record_inline, [$1]]

      when /^JSONModel\(:([a-z_]*)\)\sobject$/
        [:record_inline, [$1]]

      else

        raise ASpaceImportException.new(:property_def => property_def)
      end
    end


    def self.value_filter(property_type)
      case property_type

      when /^record_uri_or_record_inline/
        lambda {|val|
          val.block_further_reception if val.respond_to? :block_further_reception
          if val.class.method_defined? :uri
            val.uri
          else
            val
          end
        }

      when /^record_uri/
        lambda {|val|
          if val.class.method_defined? :uri
            val.uri
          else
            val.to_s
          end
        }

      when /^record_inline/
        lambda {|val|
          val
        }

      when /^record_ref/
        lambda {|val|
          if val.respond_to?(:uri)
            {'ref' => val.uri}
          else
            val
          end
        }

      when :boolean
        lambda {|val|
          if [false, true].include? val
            val
          elsif val.to_s == '0'
            false
          elsif val.to_s == '1'
            true
          end
        }

      when :dynamic_enum
        lambda {|val|
          val
        }

       when /^string/
         lambda {|val|
           val.split("\n").map {|s| s.strip }.join("\n")
         }
       
       when :integer
         lambda {|val|
           val.to_i
         }

       else
         raise "Can't handle #{property_type}"
       end
     end


    def self.ref_type_list(property_ref_type)

      if property_ref_type.is_a?(Array) && property_ref_type[0].is_a?(Hash)
        property_ref_type.map { |t| t['type'].scan(/:([a-zA-Z_]*)/)[0][0] }

      elsif property_ref_type.is_a?(Array)
        property_ref_type.map { |t| t.scan(/:([a-zA-Z_]*)/)[0][0] }
      else
        property_ref_type.scan(/:([a-zA-Z_]*)/)[0][0]
      end
    end


    def self.update_record_references(record, ref_source)
      if record.is_a?(Array) || record.respond_to?(:to_array)
        record.map {|e| update_record_references(e, ref_source)}
      elsif record.is_a?(Hash) || record.respond_to?(:each)
        fixed = {}

        record.each do |k, v|
          fixed[k] = update_record_references(v, ref_source)
        end

        fixed
      else
        ref_source[record] || record
      end
    end


    class ASpaceImportException < StandardError
      attr_accessor :property
      attr_accessor :val_type
      attr_accessor :property_def

      def initialize(opts)
        @property = opts[:property]
        @val_type = opts[:val_type]
        @property_def = opts[:property_def]
      end

      def to_s
        if @property_def
          "#<:ASpaceImportException: Can't classify the property schema: #{property_def.inspect}>"
        elsif @val_type
          "#<:ASpaceImportException: Can't identify a Model for property '#{property}' of type '#{val_type}'>"
        else
          "#<:ASpaceImportException: Can't identify a schema fragment for property '#{property}'>"
        end
      end
    end

  end
end



module ASpaceMappings
  module MARC21

    def self.get_aspace_source_code(code)
      case code.to_s
      when '0'; 'lcsh'
      when '1'; 'lcshac'
      when '2'; 'mesh'
      when '3'; 'nal'
      when '4'; 'ingest'
      when '5'; 'cash'
      when '6'; 'rvm'
      else; nil
      end
    end
  end
end

