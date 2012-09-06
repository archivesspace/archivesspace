require 'psych'

module ASpaceImport
  class Crosswalk

    def initialize(yaml)
      @walk = Psych.load(yaml)
    end
    
    def to_s
      "Crosswalk from #{@@walk['source']['schema']}"
    end
    
    def properties(type)
      return nil unless @walk['entities'][type]
      @walk['entities'][type]['properties'].each do |property, xpaths|
        yield property, xpaths
      end
    end
      
    def lookup_entity_for(xpath)
      types = []
      @walk['entities'].each do |k, v|
        v['instance'].each do |xp|
          if xp.match(/(\/)*#{xpath}$/)
            types.push(k)
          end
        end
      end
      if types.count > 1
        raise StandardError.new("Found more than one entity to create with this xpath, and have no means of giving them priority: #{types.to_s}")
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
        raise StandardError.new("Found more than one property to create with this xpath, and have no means of giving them priority: #{properties.to_s}")
      else
        properties.pop
      end
    end
  end 
end