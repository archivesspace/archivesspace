module ComponentTransfer

  include JSONModel
  extend JSONModel

  def self.included(base)
    base.extend(JSONModel)
  end

  module ResponseHelpers
    
    def component_transfer_response(resource_uri, archival_object_uri)

      begin
        (ao, event) = ComponentTransfer.transfer(resource_uri, archival_object_uri)
        json_response({:component => archival_object_uri, :resource => resource_uri, :event => event.uri}, 200)

      end
    end
  end
  
  
  def self.transfer(target_resource_uri, archival_object_uri)
    id = JSONModel(:archival_object).id_for(archival_object_uri)

    obj = ArchivalObject[:id => id]
    
    if obj.nil?
      raise NotFoundException.new("That which does not exist cannot be moved.")
    end

    # Move the children first
    deep_transfer(JSONModel::JSONModel(:resource).id_for(target_resource_uri), obj)

    # Now move the main object to the next 
    # available top-level slot in the target
    json = obj.class.to_jsonmodel(obj)

    source_resource_uri = json['resource']['ref']

    json.resource['ref'] = target_resource_uri
    json.parent = nil

    obj.update_from_json(json, {:force_reposition => true}, false)

    # generate an event to mark this component transfer
    event = Event.for_component_transfer(archival_object_uri, source_resource_uri, target_resource_uri)

    # refresh obj as lock version would have been incremented
    # after the event was created
    obj.refresh

    # let's return the transferred object and the event
    [obj, event]
  end
    
    
  def self.deep_transfer(new_resource_id, obj)
    ArchivalObject.this_repo.filter(:root_record_id => obj.root_record_id, :parent_id => obj.id).each do |child|
      deep_transfer(new_resource_id, child)
      child.root_record_id = new_resource_id
      child.save
    end
  end
end


 
