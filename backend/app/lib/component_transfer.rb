module ComponentTransfer
  
  
  module ResponseHelpers
    
    def component_transfer_response(resource_uri, archival_object_uri)

      begin
        ComponentTransfer.transfer(resource_uri, archival_object_uri)
        json_response({:component => archival_object_uri, :resource => resource_uri}, 200)
        
      # rescue
      #   json_response({:error => "Something went wrong..."}, 501)
      end
    end
  end
  
  def self.transfer(resource_uri, archival_object_uri)
    
    id = JSONModel(:archival_object).id_for(archival_object_uri)
    
    if !id
      raise NotFoundException.new("That which does not exist cannot be moved.")
    end
    
    obj = ArchivalObject.to_jsonmodel(id)
    
    obj.resource['ref'] = resource_uri
    
    obj.save
  end
    
end


 
