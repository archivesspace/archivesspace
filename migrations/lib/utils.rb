module ASpaceImport
  module Utils
    
    # Fake an ID to create URIs
    def self.mint_id
      @counter ||= 1000000
      @counter += 1
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
           {'ref' => val.uri}
         }

       when :boolean
         lambda {|val|
           if val.to_s == '0'
             false
           elsif val.to_s == '1'
              true
           end
         }

       when :dynamic_enum
         lambda {|val|
           val.downcase
         }

       when /^string/
         lambda {|val|
           val.sub(/[\s\n]*$/, '')
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
   
     # @param json - JSON Object to be modified
     # @param ref_source - a hash mapping old uris to new uris
     # The ref_source values are evaluated by a block
   
     def self.update_record_references(json, ref_source)

       data = json.to_hash
       data.each do |k, v|

         property_type = get_property_type(json.class.schema["properties"][k])[0]

         if property_type == :record_ref && ref_source.has_key?(v['ref'])
           data[k]['ref'] = yield ref_source[v['ref']]
         
         elsif property_type == :record_ref_list

           v.each {|li| li['ref'] = yield ref_source[li['ref']] if ref_source.has_key?(li['ref'])}
                
         elsif property_type.match(/^record_uri(_or_record_inline)?$/) \
           and v.is_a? String \
           and !v.match(/\/vocabularies\/[0-9]+$/) \
           and ref_source.has_key?(v)

           data[k] = yield ref_source[v]
         
         elsif property_type.match(/^record_uri(_or_record_inline)?_list$/) && v[0].is_a?(String)
           data[k] = v.map { |vn| (vn.is_a?(String) && vn.match(/\/.*[0-9]$/)) && ref_source.has_key?(vn) ? (yield ref_source[vn]) : vn }
         end    
       end
     
       json.set_data(data)
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