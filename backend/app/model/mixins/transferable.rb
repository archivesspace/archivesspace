module Transferable

  def transfer_to_repository(repository, transfer_group = [])
    events_to_clone = []
    containers_to_clone = {}
    
    # the relationship between SC and TCs
    topcon_rlshp = SubContainer.find_relationship(:top_container_link) 
    # now we get  all the relationships in this graph 
    all_ids = self.object_graph.ids_for(topcon_rlshp)
    
    all_ids.each do |rel_id| 
      DB.open do |db|
        # let's look for all the TC ids 
        db[:top_container_link_rlshp].filter(:id => rel_id).each do |tc_rel|
          
          # lets get all the top_containers outside this graph
          number_of_tc_links = db[:top_container_link_rlshp].filter( :top_container_id => tc_rel[:top_container_id])
                                                            .exclude( :id => all_ids  )
                                                            .count
          
          if number_of_tc_links < 1 # this tc is only linked in this graph..so we transfer
            TopContainer[tc_rel[:top_container_id]].transfer_to_repository(repository, transfer_group + [self]) # i guess we always add self just in case. dups are uniqed out. 
          else # something outside the graph is linked to it, add it to the list and we'll clone after transfer
            tc_id = tc_rel[:top_container_id] 
            containers_to_clone[tc_id] ||= [] 
            containers_to_clone[tc_id] <<  tc_rel[:sub_container_id]
          end 
        end
      end
    end 
    
    Event.find_relationship(:event_link).who_participates_with(self).each do |event|
      linked_records = event.related_records(:event_link)

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

    if !containers_to_clone.empty?
      containers_to_clone.each do |tc_to_clone, sces|
        # we copy the TC to be cloned 
        hash =  TopContainer.to_jsonmodel(tc_to_clone).to_hash(:trusted)
       
        # we make the TC in the new repo context
        RequestContext.open(:repo_id => repository.id) do
          tc = nil 
          
          # but first lets check if this exists already by barcode 
          if hash["barcode"]
            tc = TopContainer.for_barcode(hash["barcode"])
          end
          
          # not found,  we make the clone   
          unless tc
            tc = TopContainer.create_from_json(JSONModel(:top_container).from_hash(hash),
                                 :repo_id => repository.id)
          end 
          
          # now we linke the clone to all the sub_containers 
          sces.each do |sc|
            # the record is broken now, so we have to shuck it in the backdoor 
            DB.open do |db|
              db[:top_container_link_rlshp].insert(:top_container_id => tc.id, 
                                                 :system_mtime => Time.now, :user_mtime => Time.now, 
                                                 :sub_container_id => sc)
            end
          end 
          
        end       
      end
    
    end

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
