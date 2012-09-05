require 'psych'

module ASpaceImport
  class Crosswalk

    def initialize(yaml)
      # load in the YAML
      # create a class represeting the crosswalk
  
      @@walk = Psych.load(yaml)
    end
    
    def to_s
      "Crosswalk from #{@@walk['source']['schema']}"
    end
      
    def lookup_entity_for(node)
      types = []
      @@walk['entities'].each do |type, xpaths|
        xpaths.each do |xp|
          if xp.match(/(\/)*#{node}$/)
            types.push(type)
          end
        end
      end
      if types.count > 1
        raise StandardError.new("Found more than one entity to create with this xpath, and have no means of giving them priority: #{types.to_s}")
      else
        types.pop
      end
    end
    
    def lookup_property_for(string)
      properties = []
      @@walk['properties'].each do |property, xpaths|
        xpaths.each do |xp|
          if xp.match(/^(\/)*(@)?#{string}$/)
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