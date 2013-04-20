module ComponentTransfer

  include JSONModel
  extend JSONModel

  def self.included(base)
    base.extend(JSONModel)
  end

  module ResponseHelpers
    
    def component_transfer_response(resource_uri, archival_object_uri)

      begin
        ComponentTransfer.transfer(resource_uri, archival_object_uri)
        json_response({:component => archival_object_uri, :resource => resource_uri}, 200)

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

    json.parent = nil

    source_resource_uri = json['resource'][:ref]

    json.resource['ref'] = target_resource_uri
    
    obj.update_from_json(json, {}, false)

    # generate an event to mark this component transfer
    # first get the current user
    user = User[:username => RequestContext.get(:current_username)]
    # build the event
    event = JSONModel(:event).from_hash({
      "event_type" => "component_transfer",
      "date" => {
        "label" => "modified",
        "date_type" => "single",
        "begin" => Time.now.strftime("%Y-%m-%d"),
        "begin_time" => Time.now.strftime("%H:%M:%S"),
      },
      "linked_records" => [
        {"role" => "source", "ref" => source_resource_uri},
        {"role" => "outcome", "ref" => target_resource_uri},
      ],
      "linked_agents" => [
        {"role" => "implementer", "ref" => JSONModel(:agent_person).uri_for(user.agent_record_id)}
      ]
    })
    # save the event to the DB in the global context
    Event.create_from_json(event)

    obj
  end
    
    
  def self.deep_transfer(new_resource_id, obj)
    ArchivalObject.this_repo.filter(:root_record_id => obj.root_record_id, :parent_id => obj.id).each do |child|
      deep_transfer(new_resource_id, child)
      child.root_record_id = new_resource_id
      child.save
    end
  end
end


 
