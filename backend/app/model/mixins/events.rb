module Events

  def self.included(base)
    ArchivesSpaceService.loaded_hook do
      base.define_relationship(:name => :event_link,
                               :json_property => 'linked_events',
                               :contains_references_to_types => proc {[Event]})
    end

  end

end
