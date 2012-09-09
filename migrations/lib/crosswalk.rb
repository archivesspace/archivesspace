require 'psych'

module ASpaceImport
  class Crosswalk

    def initialize(yaml)
      @walk = Psych.load(yaml)
      @schema = nil
    end
    
    def to_s
      "Crosswalk from #{@@walk['source']['schema']}"
    end
    
    def properties(type = @schema)
      return nil unless @walk['entities'][type]
      @walk['entities'][type]['properties'].each do |property, xpaths|
        yield property, xpaths
      end
    end
    
    def relationships(type = @schema)
      return nil unless @walk['entities'][type]
      @walk['entities'][type]['relationships'].each do |relationship, xpaths|
        yield relationship, xpaths
      end
    end     
    
    def ancestor_relationships(schema = @schema)
      relationships(schema) do |r, xpaths|
        if xpaths.find {|xp| xp.match(/^parent::([a-z]*)$/) or xp.match(/^ancestor::([a-z]*)$/) }
          yield lookup_entity_for($1), r #does this work if the 2nd match is made?
        end
      end
    end
    
    # these ^v can be merged?
    
    def get_property(schema = @schema, xpath)
      if (property = lookup_property_for(schema, xpath))
        yield property 
      end
    end
    
    def set_schema(node_name)      
      @schema = lookup_entity_for(node_name)
      yield @schema if @schema
    end
    

      
    def lookup_entity_for(xpath)
      types = []
      @walk['entities'].each do |k, v|
        v['instance'].each do |xp|
          if xp.match(/^(\/)*#{xpath}$/)
            types.push(k)
          end
        end
      end
      if types.count > 1
        raise StandardError.new("Found more than one entity to create with this xpath #{xpath}, and have no means of giving them priority: #{types.to_s}")
      else
        types.pop
      end
    end
    
    def lookup_property_for(type, xpath)
      return nil unless @walk['entities'][type]
      properties = []
      @walk['entities'][type]['properties'].each do |property, xpaths|
        xpaths.each do |xp|
          if xp.match(/^(\/)*(@)?#{xpath}$/)
            properties.push(property)
          end
        end
      end
      if properties.count > 1
        raise StandardError.new("Found more than one property to create with this xpath (#{xpath}), and have no means of giving them priority: #{properties.to_s}")
      else
        properties.pop
      end
    end
  end 
end