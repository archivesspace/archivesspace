require 'psych'

module ASpaceImport
  module Crosswalk
    
    # Module methods and helpers  
      
    def self.init(opts)

      @models = {}
      @walk = Psych.load(IO.read(File.join(File.dirname(__FILE__),
                                                "../crosswalks",
                                                "#{opts[:crosswalk]}.yml")))
                                                
      @regex_cache = {}
    end 
  
    def self.walk     
      @walk
    end
    
    def self.models
      @models
    end
    
    def self.mint_id
      @counter ||= 0
      @counter += 1
    end
    
    # Returns a regex object that is used to match the xpath of a 
    # parsed node with an xpath definition in the crosswalk. In the 
    # case of properties, the offset is the depth of the predicate 
    # node less the depth of the subject node. An offset of nil
    # indicates a root perspective.
    
    def self.regexify_xpath(xp, offset = nil)
      
      # Slice the xpath based on the offset
      # escape for `text()` nodes
      unless offset.nil? || offset < 1
        xp = xp.scan(/[^\/]+/)[offset*-1..-1].join('/')
        xp.gsub!(/\(\)/, '[(]{1}[)]{1}')
      end
      
      @regex_cache[xp] ||= {}
      
      case offset
        
      when nil
        @regex_cache[xp][offset] ||= Regexp.new "^(/|/" << xp.split("/")[1..-2].map { |n| 
                                "(child::)?(#{n}|\\*)" 
                                }.join('/') << ")" << xp.gsub(/.*\//, '/') << "$"
        
      when 0
        @regex_cache[xp][offset] ||= /^[\/]?#{xp.gsub(/.*\//, '')}$/

      when 1..100
        @regex_cache[xp][offset] ||= Regexp.new "^(descendant::|" << xp.scan(/[a-zA-Z_]+/)[offset*-1..-2].map { |n| 
                                "(child::)?(#{n}|\\*)" 
                                }.join('/') << (offset > 1 ? "/" : "") << "(child::)?)" << xp.gsub(/.*\//, '') << "$"

      
      when -100..-1
        @regex_cache[xp][offset] ||= Regexp.new "^(ancestor::|" << ((offset-1)*-1).times.map {
                                  "parent::\\*/"
                                  }.join << "parent::)#{xp.gsub(/.*\//, '')}"
      end

      @regex_cache[xp][offset]
      
    end
    
    # class method to mix into an importer class.
    # analyzes parsing context and returns a new
    # object, a queued object, or false. also
    # wraps the object's model so that it can pick
    # up attributes from the parser.
      
    def object_for_node(*parseargs)
      xpath, ndepth, ntype, queue = *parseargs
      models = ASpaceImport::Crosswalk.models
      walk = ASpaceImport::Crosswalk.walk
      regex = ASpaceImport::Crosswalk.regexify_xpath(xpath)
      types = walk["entities"].map {|k,v| k if v["xpath"] and v["xpath"].find {|x| x.match(regex)}}.compact
      

      case types.length

      when 2..100
        raise "Too many matched entities"
      when 1 
        if ntype == 1
          models[types[0]] ||= wrap_model(JSONModel::JSONModel(types[0]))
          tweak_object(models[types[0]].new, *parseargs)
        elsif queue
          raise "Record Type mismatch in parse queue" unless queue[-1].class.record_type == types[0]
          queue[-1]
        end
      when 0
        false
      end  
    end
    
    # @param cls - a JSONModel class
    
    def wrap_model(cls)
  
      cls.class_eval do
             
        def receivers
          @property_mgr ||= ASpaceImport::Crosswalk::PropertyReceiverDispatcher.new(self)
          @property_mgr
        end
                 
        def set_default_properties
          self.receivers.each { |r| r.receive }
        end
        
        def tmp_vals
          @tmp_vals ||= {}
        end
              
        def depth
          @depth ||= 0
        end
        
        def xpath
          @xpath ||= nil
        end
        
        def block_further_reception
          @done_being_received = true
        end

        def done_being_received?
          @done_being_received ||= false
          @done_being_received
        end
        
        attr_accessor :depth
        attr_accessor :xpath
        
      end

      cls
    end  
    
    def tweak_object(json, *parseargs)
      json.xpath, json.depth = *parseargs

      # Set a pre-save URI to be dereferenced by the backend
      if json.class.method_defined? :uri
        json.uri = json.class.uri_for(ASpaceImport::Crosswalk.mint_id) 
      end
      
      json
    end   

    # Intermediate / chaining class for yielding property receivers given
    # either an xpath or a record_type along with an optional depth (of
    # the parsing context into which the reciever will be yielded)

    class PropertyReceiverDispatcher
      
      def initialize(json)
        @json = json
        @depth = @json.depth
        @receivers = {}
        ASpaceImport::Crosswalk.property_receivers(@json.class).each do |p, r|
          @receivers[p] = r.new(@json)
        end 
      end
      
      def each
        @receivers.each { |p, r| yield r }                  
      end
      
      # Given *nodeargs, yield property receivers
      # that will take data from the parsing context
      # and apply it to the JSON object
      
      def for_node(*nodeargs)
        xpath, depth, ntype = *nodeargs

        return unless xpath

        offset = depth ? depth - @depth : 0 
        xpath_regex = ASpaceImport::Crosswalk::regexify_xpath(xpath, offset) 

        @receivers.each do |p, r|          
          yield r if r.receives_node? xpath_regex
        end 
      end
      
      # Generate receivers for another json object
      # parsed earilier or later.
      
      def for_obj(json)

        @receivers.each do |p, r|
          yield r if r.receives_obj? json
        end
      end
      
    end
    
    # Generate receiver classes for each property of a 
    # json model

    def self.property_receivers(model)
      receivers = {}
      
      @walk['entities'][model.record_type]['properties'].each do |p, defn|
         receivers[p] = self.initialize_receiver(p, model.schema['properties'][p], defn)
      end
     
      receivers
    end

    # @param property_name - [String] the name of the property
    # @param def_from_schema - [Hash] the schema fragement that defines the property
    # @param def_from_xwalk - [Hash] the crosswalk fragment that maps source data to 
    #  the property
    
    def self.initialize_receiver(property_name, def_from_schema, def_from_xwalk)
      
      Class.new(PropertyReceiver) do
        
        class << self
          attr_reader :property
          attr_reader :property_type
          attr_reader :sdef
          attr_reader :xdef
          attr_reader :received_jsonmodel_types
        end
        
        @property = property_name
        @property_type, @received_jsonmodel_types = ASpaceImport::Crosswalk.get_property_type(def_from_schema)
        @sdef, @xdef = def_from_schema, def_from_xwalk
        
        if @property_type.match /^record/ 
          if @received_jsonmodel_types.empty?
            raise CrosswalkException.new(:property => @property, :val_type => @property_type) 
          end
        end        
      end
    end
    
    class CrosswalkException < StandardError
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
          "#<:CrosswalkException: Can't classify the property schema: #{property_def.inspect}>"
        else
          "#<:CrosswalkException: Can't identify a Model for property #{property} of type #{val_type}>"
        end
      end
    end
    
    
    # Objects to manage the setting of a property of the
    # master json object (@object)  
    
    class PropertyReceiver
      attr_reader :object
      
      def initialize(json)
        @object = json
        @cache = {}
      end
      
      def to_s
        "Property Receiver for #{@object.class.record_type}\##{self.class.property}"
      end
      
      # Determine if this receiver will accept another object 
      # as a property of the receiver's @object. 
      
      def receives_obj?(other_object)

        return false if other_object.done_being_received?

        if self.class.xdef['axis'] && self.class.received_jsonmodel_types.include?(other_object.jsonmodel_type)
        
          if self.class.xdef['axis'] == 'parent' && @object.depth - other_object.depth == 1
            true
          elsif self.class.xdef['axis'] == 'ancestor' && @object.depth - other_object.depth >= 1
            true
          elsif self.class.xdef['axis'] == 'descendant' && other_object.depth - @object.depth >= 1
            true
          else
            false
          end
          
        else
          # Fall back to testing the other object's source node
          offset = other_object.depth - @object.depth 
          receives_node? ASpaceImport::Crosswalk::regexify_xpath(other_object.xpath, offset)
        end
      end
      
      # Determine if this receiver will accept a parsed value
      # at a given xpath (relative to the receiver's @object)
      
      def receives_node?(xpath_regex)
        return false unless self.class.xdef['xpath']
        
        unless @cache.has_key?(xpath_regex)
          @cache[xpath_regex] = self.class.xdef['xpath'].find { |xp| xp.match(xpath_regex) } ? true : false
        end
        
        @cache[xpath_regex]
      end
      
      # Run defined procedures, apply defaults, and clean up
      # whitespace padding for a parsed value.
      
      def pre_process(val)
        if self.class.xdef['procedure'] && val
          proc = eval "lambda { #{self.class.xdef['procedure']} }"
          val = proc.call(val)
        end
        
        if val == nil and self.class.xdef['default'] && !@object.send("#{self.class.property}")
          val = self.class.xdef['default']
        end
        
        if val.is_a? String
           val.gsub!(/^[\s\t\n]*/, '')
           val.gsub!(/[\s\t\n]*$/, '')
           val = nil if val.empty?
        end
        
        val
      end
      
      # @param val - string, hash, or JSON object
      
      def receive(val = nil)
        
        val = pre_process(val)
                
        return false if val == nil
        
        case self.class.property_type

        when /^record_uri_or_record_inline/
          val.block_further_reception if val.respond_to? :block_further_reception
          if val.class.method_defined? :uri
            val = val.uri
          elsif val.class.method_defined? :to_hash
            val = val.to_hash
          end
                  
        when /^record_uri/
          val = val.uri
          
        when /^record_inline/
          val.block_further_reception if val.respond_to? :block_further_reception
          val = val.to_hash
        
        when /^record_ref/
          if val.class.method_defined? :uri
            val = {'ref' => val.uri}
          end  
        end
        
        if self.class.property_type.match /list$/       
          val = @object.send("#{self.class.property}").push(val)
        end
        
        @object.send("#{self.class.property}=", val)
      end
    end


    # Helpers that should probably be relocated:

    def self.ref_type_list(property_ref_type)
      if property_ref_type.is_a? Array
        property_ref_type.map { |t| t['type'].scan(/:([a-zA-Z_]*)/)[0][0] }
      else  
        property_ref_type.scan(/:([a-zA-Z_]*)/)[0][0]
      end
    end
    
    # @param property_def - property fragment from a json schema
    # @returns - [property_typ_code, array_of_qualified_json_types]
    
    def self.get_property_type(property_def)

      # subrecord slots taking more than one type

      if property_def['type'].is_a? Array
        if property_def['type'].reject {|t| t['type'].match(/object$/)}.length != 0
          raise CrosswalkException.new(:property_def => property_def)
        end
        
        return [:record_inline, property_def['type'].map {|t| t['type'].scan(/:([a-zA-Z_]*)/)[0][0] }]
      end

      # all other cases

      case property_def['type']

      when 'boolean'
        [:boolean, nil]
        
      when 'string'
        [:string, nil]
        
      when 'object'
        if property_def['subtype'] == 'ref'          
          [:record_ref, ref_type_list(property_def['properties']['ref']['type'])]
        else
          raise CrosswalkException.new(:property_def => property_def)
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
        
        raise CrosswalkException.new(:property_def => property_def)
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
          data[k] = v.map { |vn| (vn.is_a? String && vn.match(/\/.*[0-9]$/)) && ref_source.has_key?(vn) ? (yield ref_source[vn]) : vn }
        end    
      end
      
      json.set_data(data)
    end
  end
end
