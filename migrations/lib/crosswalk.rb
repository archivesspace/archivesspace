require 'psych'

module ASpaceImport
  module Crosswalk
      
    def self.init(opts)

      @@walk = Psych.load(IO.read(File.join(File.dirname(__FILE__),
                                                "../crosswalks",
                                                "#{opts[:crosswalk]}.yml")))
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
                
                def mapped_properties
                  @@walk['entities'][self.class.record_type]['properties']
                end
                
                
                def ancestor_relationships
                  self.mapped_properties.each do |property, hsh|

                    if hsh['xpath'].find { |xp| xp.match(/^parent::([a-z]*)$/) or 
                                                xp.match(/^ancestor::([a-z]*)$/) }
                        yield ASpaceImport::Crosswalk.lookup(:xpath => $1), property
                    end
                  end
                end
                
                
                def set_properties(opts)

                  self.mapped_properties.each do |property, hsh|

                    next unless hsh['xpath'].find { |xp| xp.match(opts[:xpath]) }                                              

                    # Allows the crosswalk to override the default
                    # behavior, which is direct value assignment
                    if hsh['procedure']
                      proc = eval "lambda { #{hsh['procedure']} }"
                      value = proc.call(opts[:value])
                    else
                      value = opts[:value]
                    end

                    next if value == nil

                    if hsh['xpath'].find { |xp| xp.match(opts[:xpath]) }

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