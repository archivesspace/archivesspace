require 'psych'

module ASpaceImport
  module Crosswalk
    
    # Part 1: Module Methods and Helpers  
      
    def self.init(opts)

      @models = {}
      @walk = Psych.load(IO.read(File.join(File.dirname(__FILE__),
                                                "../crosswalks",
                                                "#{opts[:crosswalk]}.yml")))
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
    
    # Returns a regex object that will be used to determine if a parsing
    # context is relevant to a JSON object in the queue.  The depth offset
    # is the node.depth of the parsing context that created the JSON
    # object, less the node.depth of the current parsing context. If a node
    # is being tested to see if it yields a JSON object, depth offset is 
    # just the node.depth.

    def self.regexify_node(node_name, depth_offset = 0)

      case depth_offset

      when -100..-2
        /^ancestor::#{node_name}$/
      when -1
        /^(parent|ancestor)::#{node_name}$/          
      when 0
        /^[\/]?#{node_name}$/
      when 1
        /^((child|descendant)::|\/\/)#{node_name}$/
      when 2
        /^((child::\*\/child|descendant)::|\/\/)#{node_name}$/
      when 3
        /^((child::\*\/child::\*\/child|descendant)::|\/\/)#{node_name}$/
      when 4
        /^((child::\*\/child::\*\/child::\*\/child|descendant)::|\/\/)#{node_name}$/
      when 5..100
        /^(descendant::|\/\/)#{node_name}$/
      end
    end
    
    # Part 2: ClassMethods to mix into an including Importer
    # Mixing into the class rather than the instance because
    # certain classes of Importer will require Crosswalks.
      
    def object_for_node(*parseargs)
      nname, ndepth, ntype, queue = *parseargs
      models = ASpaceImport::Crosswalk.models
      walk = ASpaceImport::Crosswalk.walk
      regex = ASpaceImport::Crosswalk.regexify_node(nname, ndepth)
      types = walk["entities"].map {|k,v| k if v["xpath"] and v["xpath"].find {|x| x.match(regex)}}.compact

      case types.length

      when 2..100
        raise "Too many matched entities"
      when 1 
        if ntype == 1
          models[types[0]] ||= wrap_model(JSONModel::JSONModel(types[0]), nname)
          tweak_object(models[types[0]].new, ndepth)
        elsif queue
          raise "Record Type mismatch in parse queue" unless queue[-1].class.record_type == types[0]
          queue[-1]
        end
      when 0
        false
      end  
    end
    
    def wrap_model(cls, node_name)
      
      cls.class_eval("def self.xpath; '#{node_name}'; end")
      
      cls.class_eval do
             
        def receivers
          @property_mgr ||= ASpaceImport::Crosswalk::PropertyMgr.new(self)
          
          @property_mgr
        end
                 
        def set_default_properties
          self.receivers.each { |r| r.receive }
        end
        
      end

      cls
    end  
    
    def tweak_object(json, depth)
      json.instance_eval("def depth; #{depth}; end")

      # Set a pre-save URI to be dereferenced by the backend
      if json.class.method_defined? :uri
        json.uri = json.class.uri_for(ASpaceImport::Crosswalk.mint_id) 
      end
      
      json
    end   
    # end  

    # Intermediate / chaining class for yielding property receivers given
    # either an xpath or a record_type along with an optional depth (of
    # the parsing context into which the reciever will be yielded)

    class PropertyMgr
      
      def initialize(json)
        @json = json
        @mapped_props = ASpaceImport::Crosswalk::walk['entities'][@json.class.record_type]['properties']
        @depth = @json.depth
        @receivers = {}
        
        @mapped_props.each do |p, defn|
          @receivers[p] ||= ASpaceImport::Crosswalk::PropertyReceiver.new(@json, p, defn)
        end        
      end
      
      def each
        @receivers.each { |p, r| yield r }                  
      end
      
      def for(*nodeargs)
        nname, ndepth, ntype = *nodeargs
        if ndepth
          offset = ndepth - @depth
        else
          offset = 0
        end                 
        
        if nname
        
          match_string = ASpaceImport::Crosswalk::regexify_node(nname, offset)
        
          @mapped_props.each do |p, defn|
            
            # No need to re-set 
            next if @json.send("#{p}") and @json.class.schema['properties'][p]['type'] == 'string'
 
            next unless defn['xpath']
 
            if defn['xpath'].find { |xp| xp.match(match_string) }

              @receivers[p] ||= ASpaceImport::Crosswalk::PropertyReceiver.new(@json, p, defn)
            
              yield @receivers[p]
            
            end
          end         
        end
      end
    end
    
    # Capable of receiving values from a parsing situation
    # and assigning them to the object and property the 
    # receiver refers to
    
    class PropertyReceiver
      attr_reader :prop
      attr_reader :json
      
      def initialize(json, prop, defn)
        @json, @prop, @defn = json, prop, defn
        @type = @json.class.schema['properties'][@prop]['type']        
      end
      
      def to_s
        "Property Receiver for #{@json.class.record_type}\##{@prop}"
      end
      
      # Takes a string, hash, or JSON object (val) that satisfies
      # a property of the JSON object to which the PropertyReceiver 
      # instance belongs. Uses the crosswalk definition (defn) to 
      # massage the val as necessary.
      
      def receive(val = nil)

        if val == nil and @defn['default'] and not @json.send("#{@prop}")
          val = @defn['default']
        end
        
        return false if val == nil
                
        if @defn['procedure']
          proc = eval "lambda { #{@defn['procedure']} }"
          val = proc.call(val)                    
        end
                        
        return false if val == nil
        
        if val.class.method_defined? :jsonmodel_type
          if @type.match(/^JSON.*(uri|uri_or_object)$/) and val.class.method_defined? :uri
            @json.send("#{@prop}=", val.uri)

          elsif @type.match(/^JSON.*object$/)
            @json.send("#{@prop}=", val.to_hash)

          elsif @type == 'array' and val.class.method_defined? :uri
            @json.send("#{@prop}=", @json.send("#{@prop}").push(val.uri))

          elsif @type == 'array'
            @json.send("#{@prop}=", @json.send("#{@prop}").push(val.to_hash(true)))
          
          else  
            raise "Unexpected condition in property receiver"
          end
             
        elsif @type == 'string'

          @json.send("#{@prop}=", val)

        elsif @type == 'array'
          if @json.send("#{@prop}")
            @json.send("#{@prop}=", @json.send("#{@prop}").push(val))
          end
        end
        true
      end
    end
  end
end