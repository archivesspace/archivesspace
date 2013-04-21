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
                  

      event = JSONModel(:event).from_hash(
                :linked_agents => [{:ref => agent_uri, :role => 'implementer'}], 
                :event_type => 'cataloging', 
                :timestamp => Time.now.utc.iso8601, 
                :linked_records => [{:ref => obj.uri, :role => 'outcome'}]
                )


      # Use the global repository to capture events about global records
      RequestContext.open(:repo_id => 1) do
        event_obj = Event.create_from_json(event, :system_generated => true)
      end

      # Refresh the object from the database here because creating the event
      # that links to it will have incremented its version number.
      obj.refresh

      obj
    end
    
  end
  
end
