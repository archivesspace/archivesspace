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
    
    id = JSONModel::JSONModel(:archival_object).id_for(archival_object_uri)
  
    obj = ArchivalObject[:id => id]
    
    if obj.nil?
      raise NotFoundException.new("That which does not exist cannot be moved.")
    end
    
    # Move the children first
    deep_transfer(JSONModel::JSONModel(:resource).id_for(resource_uri), obj)

    # Now move the main object to the next 
    # available top-level slot in the target
    json = obj.class.to_jsonmodel(obj)
    
    json.parent = nil
    
    json.resource['ref'] = resource_uri
    
    obj.update_from_json(json, {}, false)
  end
    
    
  def self.deep_transfer(new_resource_id, obj)
    
    ArchivalObject.this_repo.filter(:root_record_id => obj.root_record_id, :parent_id => obj.id).each do |child|
      deep_transfer(new_resource_id, child)
      child.root_record_id = new_resource_id
      child.save
    end
  end
end


 
