module ComponentTransfer
  
  
  module ResponseHelpers
    
    def component_transfer_response(resource_uri, archival_object_uri)

      begin
        ComponentTransfer.transfer(resource_uri, archival_object_uri)
        json_response({:component => archival_object_uri, :resource => resource_uri}, 200)
  
      end
    end
  end
  
  
  def self.transfer(resource_uri, archival_object_uri)
    
    id = JSONModel(:archival_object).id_for(archival_object_uri)
  
    obj = ArchivalObject[:id => id]
    
    if obj.nil?
      raise NotFoundException.new("That which does not exist cannot be moved.")
    end
    
    deep_transfer(JSONModel(:resource).id_for(resource_uri), obj)
  end
    
    
  def self.deep_transfer(new_resource_id, obj)
    
    ArchivalObject.this_repo.filter(:root_record_id => obj.root_record_id, :parent_id => obj.id).each do |child|
      deep_transfer(new_resource_id, child)
    end

    obj.root_record_id = new_resource_id
    obj.save
  end
end


 
