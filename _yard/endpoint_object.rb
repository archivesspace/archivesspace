module YARD::CodeObjects
  
  class EndpointObject < Base
    # Just to skip java dependencies
    def self.helpers
      nil
    end
    
    include RESTHelpers
    
    def type
      :endpoint
    end
    
    def return_types
      nil
    end
     
    def describe

      e = eval("#{self.source}")
      
      self[:meth] = e[:method]
      
      self[:description] = e[:description]
      
      # self[:params] = Array.new
      # 
      # e[:required_params].each do |param|
      #   
      #   opts = (param[3] or {})
      # 
      #   vs = opts[:validation] ? " -- #{opts[:validation][0]}" : ""
      # 
      #   if opts[:body]
      #     self[:params] << "#{param[1]} <request body> -- #{param[2]}#{vs}"
      #   else
      #     self[:params] << "#{param[1]} #{param[0]} -- #{param[2]}#{vs}"
      #   end
      # end
      # 
      # self[:returns] = Array.new
      # e[:returns].each do |ret|
      #   self[:returns] << "#{ret[0]} -- #{ret[1]}"
      # end    

      self
      
    end
  end
end