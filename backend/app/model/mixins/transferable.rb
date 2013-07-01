module Transferable

  def transfer_to_repository(repository, transfer_group = [])
    events_to_clone = []

    Event.find_relationship(:event_link).who_participates_with(self).each do |event|
      linked_records = event.linked_records(:event_link)

      if linked_records.length == 1
        # Events whose linked_records list contains only the record being
        # transferred should themselves be transferred.
        event.transfer_to_repository(repository, transfer_group + [self])
      else
        event_json = Event.to_jsonmodel(event)
        event_role = event_json.linked_records.find {|link| link['ref'] == self.uri}['role']

        events_to_clone << {:event => event_json, :role => event_role}
      end
    end

    # Continue with the transfer
    super

    # Clone any required events in the new repository
    if !events_to_clone.empty?
      RequestContext.open(:repo_id => repository.id) do

        events_to_clone.each do |to_clone|
          event = to_clone[:event].to_hash(:trusted).
                                   merge('linked_records' => [{
                                                                'ref' => self.uri,
                                                                'role' => to_clone[:role]
                                                              }])

          Event.create_from_json(JSONModel(:event).from_hash(event),
                                 :repo_id => repository.id)
        end
      end
    end
  end

end
