require 'psych'

module ASpaceImport
  class Crosswalk
    include JSONModel


    def initialize(yaml)
      @walk = Psych.load(yaml)
    end
    
    
    def to_s
      "Crosswalk from #{@walk['source']['schema']}"
    end

    # Given an xpath, return true if
    # the crosswalk maps it to a JSON
    # Model. Return a JSONModel for
    # any match if given a block
    # Example:
    #   
    #   Crosswalk.models(:xpath => 'c')
    #     => true

    def models(opts)

      if (schemata = lookup_entities_for(opts))
        schemata.each do |s|            
          if (jm = JSONModel(s).new)
            yield jm if block_given?
          end
        end
        
        true
      else 
        false
      end
    end
    
    
    def properties(opts)
      
      # TODO - filter out properties that won't be
      # accepted by the model?

      return nil unless @walk['entities'][opts[:type]]

      properties = {}
      
      @walk['entities'][opts[:type]]['properties'].each do |property, hsh|
        if opts[:xpath]
          if hsh['xpath'].find { |xp| xp.match(opts[:xpath]) }
            properties[property] = hsh
          end
        else
          properties[property] = hsh
        end
      end
      
      
      if properties.empty?
        false
      else
        if block_given?
          properties.each do |p, hsh|
            yield p, hsh
          end
        end
        
        true
      end
    end
    
    
    
    def ancestor_relationships(opts)
      
      return nil unless @walk['entities'][opts[:type]]
      
      @walk['entities'][opts[:type]]['properties'].each do |property, hsh|

        if hsh['xpath'].find { |xp| xp.match(/^parent::([a-z]*)$/) or xp.match(/^ancestor::([a-z]*)$/) }
            yield lookup_entities_for(:xpath => $1), property
        end
      end


    end
    
    
    
    # Remove this:
    
    def get_property(schema, xpath)
      
      if (property = lookup_property_for(schema, xpath))
        yield property 
      end
    end
 
    


    

    def lookup_entities_for(opts)
      types = []
      @walk['entities'].each do |k, v|
        v['xpath'].each do |xp|
          if xp.match(/^(\/)*#{opts[:xpath]}$/)
            types.push(k) unless opts[:type] and k != opts[:type] # fix this
          end
        end
      end
      if types.count > 0
        types
        # raise StandardError.new("Found more than one entity to create with this xpath #{xpath}, and have no means of giving them priority: #{types.to_s}")
      else
        nil
      end
    end
    
    def lookup_property_for(type, xpath)
      return nil unless @walk['entities'][type]
      props = []
      @walk['entities'][type]['properties'].each do |k, v|
        v['xpath'].each do |xp|
          if xp.match(/^(\/)*(@)?#{xpath}$/)
            props.push(k)
          end
        end
      end
      if props.count > 1
        raise StandardError.new("Found more than one property to create with this xpath (#{xpath}), and have no means of giving them priority: #{props.to_s}")
      else
        props.pop
      end
    end
  end 
end