require 'psych'

module ASpaceWalk
  include JSONModel

  @@walks = {}
  
  def self.get_5 
    5
  end
  
  def self.load_walk(yaml)
    # load in the YAML
    # create a class represeting the crosswalk
    cls = Class.new do
      
      @@source = Psych.load(yaml)
      puts Psych.dump(@@source)

      def self.to_s
        "ASpaceWalk from #{@@source['source_format']}"
      end

      def self.causes_object?(node)
        @@source['objects'].each do |type, obj|
          xpath = obj['xpath']
          if xpath.match(/(\/)*#{node}/)
            return true
          end
        end  
        return false
      end
    end
    
    cls
  
  end
    
end