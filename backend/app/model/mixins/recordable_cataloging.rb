module RecordableCataloging

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def create_from_json(json, opts = {})

      obj = super

      agent_uri = AgentSoftware.archivesspace_record.uri

      # If the current user has a linked agent, use it.
      if !opts[:system_generated]
        user = User[:username => RequestContext.get(:current_username)]
        if user.agent_record_id
          agent_uri = uri_for(:agent_person, user.agent_record_id)
        end
      end

      Event.for_cataloging(agent_uri, obj.uri)

      # Refresh the object from the database here because creating the event
      # that links to it will have incremented its version number.
      obj.refresh

      obj
    end

  end

end
