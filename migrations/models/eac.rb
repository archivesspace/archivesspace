ASpaceExport::model :eac do    

  def initialize(obj)
    @json = obj
  end
  
  def self.from_aspace_object(obj)
  
    self.new(obj)    
  end
    
  
  def self.from_agent(obj)
    eac = self.from_aspace_object(obj)
  
    eac
  end
  
  def method_missing(meth)
    if @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end
  
  
end
