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
                                }.join('/') << "/(child::)?)" << xp.gsub(/.*\//, '') << "$"

      
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
    
    def wrap_model(cls)
  
      cls.class_eval do
        
        @receivers = ASpaceImport::Crosswalk.property_receivers(cls)
        
        def self.receivers
          @receivers
        end
             
        def receivers
          @property_mgr ||= ASpaceImport::Crosswalk::PropertyMgr.new(self)
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

    class PropertyMgr
      
      def initialize(json)
        @json = json
        @depth = @json.depth
        @receivers = {}

        @json.class.receivers.each do |p, r|
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
         receivers[p] = self.initialize_receiver(p, self.property_type(model.schema['properties'][p]), model.schema['properties'][p], defn)
      end
     
      receivers
    end

    # returns a Property Receiver Class for a property of
    # a JSONModel Class
    
    def self.initialize_receiver(p, val_type, schema_def, xwalk_def)
      Class.new(PropertyReceiver) do
        
        class << self
          attr_reader :property
          attr_reader :val_type
          attr_reader :sdef
          attr_reader :xdef
          attr_reader :received_jsonmodel_types
        end
        
        @property = p
        @val_type = val_type
        @sdef = schema_def
        @xdef = xwalk_def

        case @val_type 
          
        when :uri
          @received_jsonmodel_types = [@sdef['type'].scan(/:([a-zA-Z_]*)/)[0][0]]
        when :array_of_uris_or_objects
          @received_jsonmodel_types = [@sdef['items']['type'].scan(/:([a-zA-Z_]*)/)[0][0]]
        when :array_of_objects 
          if @sdef['items']['type'].is_a? Array
            @received_jsonmodel_types = []
            @sdef['items']['type'].each { |t| @received_jsonmodel_types << t['type'].scan(/:([a-zA-Z_]*)/)[0][0]}
          end
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
      
      # take a string, hash, or JSON object that satisfies
      # a property of the receiver's @object
      
      def receive(val = nil)
        
        val = pre_process(val)
                
        return false if val == nil
        
        case self.class.val_type
                  
        when :uri
          val = val.uri
        
        when :array_of_objects
          val = @object.send("#{self.class.property}").push(val.to_hash)

        when :array_of_uris_or_objects          
          if val.class.method_defined? :uri
            val = val.uri
          elsif val.class.method_defined? :to_hash
            val = val.to_hash
          end

          val = @object.send("#{self.class.property}").push(val)
          
        end               
        
        @object.send("#{self.class.property}=", val)
      end
    end
    
    # Classify properties based on JSON schemas.
    
    def self.property_type(schema_def)
      if schema_def['type'] == 'string'
        :string
      elsif schema_def['type'].match(/^JSON.*object$/)
        :object
      elsif schema_def['type'].match(/^JSON.*(uri|uri_or_object)$/)
        :uri
      elsif schema_def['type'] == 'array' && schema_def['items']['type'].is_a?(String)
        if schema_def['items']['type'].match(/^JSON.*(uri|uri_or_object)$/)
          :array_of_uris_or_objects
        elsif schema_def['items']['type'].match(/^JSON.*object$/) || schema_def['items']['type'].match(/^object$/) 
          :array_of_objects
        else
          :array_of_strings
        end
      elsif schema_def['type'] == 'array' && schema_def['items']['type'].is_a?(Array)
        :array_of_objects
      else
        :unknown
      end
    end
    
  end
end