module YARD::CodeObjects
  
  class EndpointObject < Base
    # Probably this isn't a good thing
    def self.helpers
      nil
    end
    
    include RESTHelpers
    
    def type
      :endpoint
    end
    

    
    def describe
      puts self.source
      e = eval("#{self.source}")
      self[:method] = e[:method]
      self[:description] = e[:description]
      self[:params] = []
      e[:params].each do |param|
        
    #     opts = (param[3] or {})
    # 
    #     vs = opts[:validation] ? " -- #{opts[:validation][0]}" : ""
    # 
    #     if opts[:body]
    #       puts "    #{param[1]} <request body> -- #{param[2]}#{vs}"
    #     else
    #       puts "    #{param[1]} #{param[0]} -- #{param[2]}#{vs}"
    #     end
    #   end
    # 
    # #  puts "  Returns: #{e[:returns].inspect}"
    #   puts "  Returns:"
    #   e[:returns].each do |ret|
    #     puts "    #{ret[0]} -- #{ret[1]}"
    #   end    
      
      self
    end
  end
end