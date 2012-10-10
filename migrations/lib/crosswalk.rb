require 'psych'

module ASpaceImport
  module Crosswalk
      
    def self.init(opts)

      @@walk = Psych.load(IO.read(File.join(File.dirname(__FILE__),
                                                "../crosswalks",
                                                "#{opts[:crosswalk]}.yml")))
                                                      
    end 
  
    def self.walk
      
      @@walk
    end
  
    # Returns a regex object that will be used to determine if a parsing
    # context is relevant to a JSON object in the queue.  The depth offset
    # is the node.depth of the parsing context that created the JSON
    # object, less the node.depth of the current parsing context.
    
    def self.regexify_node(node_name, depth_offset = 0)
      
      case depth_offset
        
      when -100..-2
        /^ancestor::#{node_name}$/
      when -1
        /^(parent|ancestor)::#{node_name}$/          
      when 0
        /^#{node_name}$/
      when 1
        /^(child|descendant)::#{node_name}$/
      when 2
        /^(child::\*\/child|descendant)::#{node_name}$/
      when 3..100
        /^descendant::#{node_name}$/
      end
    end
    
    # Hash lookup for record types in the crosswalk that match an xpath
      
    def self.lookup(xpath)
      
      @@types_lookup ||= {}
      
      unless @@types_lookup[xpath]
        
        types = []
        
        @@walk['entities'].each do |ent, defn|
          defn['xpath'].each do |xp|
            if xp.match(/^(\/)*#{xpath}$/)
              types.push(ent) 
            end
          end
        end
        if types.count > 0
          @@types_lookup[xpath] = types
        else
          @@types_lookup[xpath] = nil
        end
      end  
    
      puts "Lookup for #{xpath} returns #{@@types_lookup[xpath]}" if $DEBUG
    
      return @@types_lookup[xpath]

    end

    # Given an xpath, return true if the crosswalk maps it to a JSON
    # Model. Return a JSONModel for any match if given a block Example:
    #
    #   Crosswalk.target_objects(:xpath => 'c')
    #     => true

    def target_objects(opts)
      
      @@entity_map ||= {}
      
      return false if @@entity_map[opts[:xpath]] == 0
      
      unless @@entity_map[opts[:xpath]]
        
        @@walk['entities'].each do |ent, defn|

          defn['xpath'].each do |xp|

            if xp.match(/^(\/)*#{opts[:xpath]}$/)
              
              puts "Matched #{xp} using #{opts[:xpath]}" if $DEBUG
              
              if @@entity_map[opts[:xpath]]
                raise StandardError.new("Found more than one entity to create with #{xpath}.")
              end
              
              mod = JSONModel::JSONModel(ent)
              
              mod.class_eval do
                
                include JSONModel::Queueable
                
                def receivers
                  unless @property_mgr
                    @property_mgr = ASpaceImport::Crosswalk::PropertyMgr.new(self)
                  end
                  
                  @property_mgr
                end
              
                def mapped_properties
                  ASpaceImport::Crosswalk::walk['entities'][self.class.record_type]['properties']
                end
                         
                def set_default_properties
                  self.receivers.each { |r| r.receive }
                end
                
              end                
              
              raise "Trying to reset a key in @@entity_map" if @@entity_map[opts[:xpath]] and $DEBUG 
                
              @@entity_map[opts[:xpath]] = mod

            end
          end
        end
      end

      if @@entity_map[opts[:xpath]] and block_given?
        obj = @@entity_map[opts[:xpath]].new
        if opts[:depth]
          obj.instance_eval("def depth; #{opts[:depth]}; end")
        end
        
        obj.after_save { @goodimports += 1 }
        obj.after_save { @import_log.push("Imported #{obj.uri}") }
        
        yield obj
        
      elsif @@entity_map[opts[:xpath]]
        puts "XP: #{opts[:xpath]} -- EM: #{@@entity_map[opts[:xpath]]}" if $DEBUG
        true
      else
        @@entity_map[opts[:xpath]] = 0
        false
      end
    end
    
    # Intermediate / chaining class for yielding property receivers given
    # either an xpath or a record_type along with an optional depth (of
    # the parsing context into which the reciever will be yielded)

    class PropertyMgr
      
      def initialize(json_obj)
        @json_obj = json_obj
        @mapped_props = ASpaceImport::Crosswalk::walk['entities'][@json_obj.class.record_type]['properties']
        @depth = @json_obj.depth
        @receivers = {}
        
        @mapped_props.each do |p, defn|
          @receivers[p] ||= ASpaceImport::Crosswalk::PropertyReceiver.new(@json_obj, p, defn)
        end        
      end
      
      def each
        @receivers.each { |p, r| yield r }                  
      end
      
      def for(opts)
        if opts[:depth]
          offset = opts[:depth] - @depth
        else
          offset = 0
        end                 
        
        if opts[:xpath]
        
          match_string = ASpaceImport::Crosswalk::regexify_node(opts[:xpath], offset)
        
          @mapped_props.each do |p, defn|
 
            next unless defn['xpath']
 
            if defn['xpath'].find { |xp| xp.match(match_string) }

              puts "Matched #{defn['xpath']} using #{match_string}" if $DEBUG

              @receivers[p] ||= ASpaceImport::Crosswalk::PropertyReceiver.new(@json_obj, p, defn)
            
              yield @receivers[p]
            
            end
          end
        
        elsif opts[:record_type]

          if offset == -1
            regex_test = /^(parent)::([a-z]*)$/
          elsif offset < -1
            regex_test = /^(parent|ancestor)::([a-z]*)$/
          else
            return
          end
          
          @mapped_props.each do |p, defn|
 
            next unless defn['xpath']
            
            if defn['xpath'].find { |xp| xp.match(regex_test) }

              if ASpaceImport::Crosswalk::lookup($2).include?(opts[:record_type])

                @receivers[p] ||= ASpaceImport::Crosswalk::PropertyReceiver.new(@json_obj, p, defn)

                yield @receivers[p]
                
              end

            end
          end
                      
        end
      end
    end
    
    # Capable of receiving values from a parsing situation
    # and assigning them to the object and property the 
    # receiver refers to
    
    class PropertyReceiver
      
      def initialize(json_obj, prop, defn)
        @json, @prop, @defn = json_obj, prop, defn
        @type = @json.class.schema['properties'][@prop]['type']        
      end
      
      def to_s
        "Property Receiver for #{@json.class.record_type} -- #{@prop}" if $DEBUG
      end
      
      def receive(val = nil)

        if val == nil and @defn['default'] and not @json.send("#{@prop}")
          val = @defn['default']
        end
        
        return if val == nil
        
        if @defn['procedure']
          proc = eval "lambda { #{@defn['procedure']} }"
          val = proc.call(val)
          puts "Procedure Val: #{val}" if $DEBUG
        end
        
        return if val == nil
        
        if @type == 'string'
          
          @json.send("#{@prop}=", val)
        elsif @type == 'array'
          
          if @json.send("#{@prop}")
            new_arr = @json.send("#{@prop}")
            new_arr.push(val)
            @json.send("#{@prop}=", new_arr)
          else
            @json.send("#{@prop}=", [val])
          end
        # can add more complexity here as needed
        elsif @type.match(/^JSONModel/) 
          
          puts "Set JSON uri on #{@prop} -- uri is #{val} -- type is #{@type}" if $DEBUG
          @json.send("#{@prop}=", val)
        end
      end
    end
  

    
  end
end