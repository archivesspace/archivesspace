require 'psych'

module ASpaceImport
  module Crosswalk
      
    def self.init(opts)

      @@walk = Psych.load(IO.read(File.join(File.dirname(__FILE__),
                                                "../crosswalks",
                                                "#{opts[:crosswalk]}.yml")))
    end 
  
    
    # Returns a regex object that will be used to determine if a parsed
    # node is relevant to a given JSON object in the queue.
    # The depth offset is the node.depth of the node that created the 
    # JSON object, less the node.depth of the node that potentially contains
    # a property for the JSON object (which might be the same node)
    
    def self.regexify_node(node_name, depth_offset = 0)
      
      case depth_offset
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
      
            
    # Given an xpath, return true if
    # the crosswalk maps it to a JSON
    # Model. Return a JSONModel for
    # any match if given a block
    # Example:
    #   
    #   Crosswalk.target_objects(:xpath => 'c')
    #     => true

    def target_objects(opts)
      
      @@entity_map ||= {}
      
      unless @@entity_map[opts[:xpath]]
        
        @@walk['entities'].each do |k, v|

          v['xpath'].each do |xp|

            if xp.match(/^(\/)*#{opts[:xpath]}$/)
              
              if @@entity_map[opts[:xpath]]
                raise StandardError.new("Found more than one entity to create with #{xpath}.")
              end
              
              mod = JSONModel::JSONModel(k)
              
              mod.class_eval do
                
                include JSONModel::Queueable

                def ancestor_relationships
                  self.mapped_properties.each do |property, hsh|

                    next unless hsh['xpath']
                    
                    if hsh['xpath'].find { |xp| xp.match(/^parent::([a-z]*)$/) or 
                                                xp.match(/^ancestor::([a-z]*)$/) }
                        yield ASpaceImport::Crosswalk.lookup(:xpath => $1), property
                    end
                  end
                end
                   
                def mapped_properties(src = {})
                  if src[:xpath]
                    result = {}

                    @@walk['entities'][self.class.record_type]['properties'].each do |p, defn|
                      next unless defn['xpath']
                      result[p] = defn if defn['xpath'].find { |xp| xp.match(src[:xpath]) }
                    end
                    
                    result                      
                    
                  else  
                    @@walk['entities'][self.class.record_type]['properties']
                  end
                end
                
                def set_default_properties
                  
                  self.mapped_properties.each do |prop, defn|
                    
                    next unless defn['default']
                    
                    if defn['procedure']
                      proc = eval "lambda { #{defn['procedure']} }"
                      value = proc.call(defn['default'])
                    else
                      value = defn['default']
                    end
                    
                    case self.class.schema['properties'][prop]['type']
                    when 'string'                    
                      # Don't overwrite an existing value with a default
                      next if self.send("#{prop}") 
                      self.send("#{prop}=", value)
                    when 'array'
                      if self.send("#{prop}")
                        new_arr = self.send("#{prop}")
                        new_arr.push(value)
                        self.send("#{prop}=", new_arr)
                      else
                        self.send("#{prop}=", [value])
                      end
                    end   
                  end
                end
                          
                
                def set_properties(src, &block)

                  if src[:depth]
                    offset = src[:depth] - self.depth
                  else
                    offset = 0
                  end
                  
                  match_string = ASpaceImport::Crosswalk::regexify_node(
                                                    src[:xpath], offset)

                  self.mapped_properties(src).each do |property, defn|

                    if defn['xpath'].find { |xp| xp.match(match_string) }
                      
                      src[:value] = Proc.new(&block).call if block_given?

                      # Allows the crosswalk to override the default
                      # behavior, which is direct value assignment
                    
                      if defn['procedure']
                        proc = eval "lambda { #{defn['procedure']} }"
                        value = proc.call(src[:value])
                      else
                        value = src[:value]
                      end

                      next if value == nil
                      
                      if value.length > 1000
                        raise "Trying to set #{property} on #{self.class.record_type} using a suspciously\
                        large value #{value.length}"
                      end

                      if (type = self.class.schema['properties'][property]['type'])

                        if type == 'string'

                          self.send("#{property}=", value) unless self.send("#{property}")
                        elsif type == 'array' #and schema_properties[property]['items']['type'] == 'string'

                          if self.send("#{property}")

                            new_arr = self.send("#{property}")
                            new_arr.push(value)
                            self.send("#{property}=", new_arr)
                          else
                            self.send("#{property}=", [value])
                          end
                        end
                      end
                    end
                  end
                end
                
              end                
                
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
        true
      else
        false
      end
    end
    
    
    def self.lookup(opts)
      types = []
      @@walk['entities'].each do |k, v|
        v['xpath'].each do |xp|
          if xp.match(/^(\/)*#{opts[:xpath]}$/)
            types.push(k) unless opts[:type] and k != opts[:type] # fix this
          end
        end
      end
      if types.count > 0
        types
      else
        nil
      end
    end
  
  end
end