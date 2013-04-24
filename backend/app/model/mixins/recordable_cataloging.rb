module RecordableCataloging
  
  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      
      obj = super

      agent_uri = case opts[:system_generated]
                  when true
                    uri_for(:agent_software, 1)
                  else
                    user = User[:username => RequestContext.get(:current_username)]
                    uri_for(:agent_person, user.agent_record_id)
                  end
                  

      Event.for_cataloging(agent_uri, obj.uri)

      # Refresh the object from the database here because creating the event
      # that links to it will have incremented its version number.
      obj.refresh

      obj
    end
    
  end
  
end
