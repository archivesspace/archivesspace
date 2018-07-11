module Transferable

  def transfer_to_repository(repository, transfer_group = [])
    events_to_clone = []
    assessments_to_clone = []
    containers_to_clone = {}

    graph = self.object_graph

    ## Digital object instances will trigger their linked digital objects to
    ## transfer too, as long as those digital objects aren't linked to by other
    ## records.

    # We skip over tree nodes because the root record will take care of
    # transferring their linked digital objects.
    unless self.class.included_modules.include?(TreeNodes)
      do_instance_relationship = Instance.find_relationship(:instance_do_link)

      # The list of instance record IDs connected to our transferee
      instance_ids = graph.ids_for(Instance)

      # The list of digital objects our transferee links to
      linked_digital_objects = do_instance_relationship
                               .filter(:id => graph.ids_for(do_instance_relationship))
                               .select(:digital_object_id)
                               .map {|row| row[:digital_object_id]}

      # The list of instance IDs that link to those digital objects (which may or
      # may not be connected to our transferee)
      instances_referencing_digital_objects = do_instance_relationship
                                              .find_by_participant_ids(DigitalObject, linked_digital_objects)
                                              .map {|r| r.instance_id}


      linked_instances_outside_transfer_set = (instances_referencing_digital_objects - instance_ids)

      if linked_instances_outside_transfer_set.empty?
        # Our record to be transferred is the only thing referencing the digital
        # objects it links to.  We can safely migrate them as well.

        DigitalObject.any_repo.filter(:id => linked_digital_objects).each do |digital_object|
          digital_object.transfer_to_repository(repository, transfer_group + [self])
        end
      else
        # Abort the transfer and provide the list of top-level records that are
        # preventing it from completing.
        exception = TransferConstraintError.new

        ASModel.all_models.each do |model|
          next unless model.associations.include?(:instance)

          model
            .eager_graph(:instance)
            .filter(:instance__id => linked_instances_outside_transfer_set)
            .select(Sequel.qualify(model.table_name, :id))
            .each do |row|
            exception.add_conflict(model.my_jsonmodel.uri_for(row[:id], :repo_id => self.class.active_repository),
                                   {:json_property => 'instances',
                                    :message => "DIGITAL_OBJECT_IN_USE"})
          end
        end

        raise exception
      end
    end

    ## Event records will be transferred if they only link to records that are
    ## being transferred too.  Otherwise, we clone the event.
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

    ## As with events, Assessment records will be transferred if they only link
    ## to records that are being transferred too.  Otherwise, we clone the
    ## assessment in the target repository.
    Assessment.find_relationship(:assessment).who_participates_with(self).each do |assessment|
      linked_records = assessment.related_records(:assessment)

      if linked_records.length == 1
        # Assessments whose linked_records list contains only the record being
        # transferred should themselves be transferred.
        assessment.transfer_to_repository(repository, transfer_group + [self])
      else
        assessment_json = Assessment.to_jsonmodel(assessment)

        assessments_to_clone << {:assessment => assessment_json}
      end
    end

    ## Transfer any top containers that aren't linked outside of the record set
    ## being cloned.  For any other linked top containers, we'll clone them in
    ## the target repository (much like events).

    # the relationship between SC and TCs
    topcon_rlshp = SubContainer.find_relationship(:top_container_link)
    # now we get  all the relationships in this graph
    all_ids = graph.ids_for(topcon_rlshp)

    DB.open do |db|
      # Find relationships that are in our set of IDs that haven't been
      # transferred yet
      db[:top_container_link_rlshp]
        .join(:top_container, :id => :top_container_id)
        .filter(:top_container_link_rlshp__id => all_ids)
        .filter(:top_container__repo_id => self.class.active_repository)
        .each do |tc_rel|
        # lets get all the top_containers outside this graph
        number_of_tc_links = db[:top_container_link_rlshp]
                             .join(:top_container, :id => :top_container_id)
                             .filter(:top_container__repo_id => self.class.active_repository)
                             .filter(:top_container_id => tc_rel[:top_container_id])
                             .exclude(:top_container_link_rlshp__id => all_ids)
                             .count

        if number_of_tc_links < 1
          # this tc is only linked in this graph..so we transfer
          top_container = TopContainer.this_repo.filter[tc_rel[:top_container_id]]

          if top_container
            if top_container.barcode && TopContainer.any_repo[:barcode => top_container.barcode, :repo_id => repository.id]
              # There's already a top container with our barcode in the target
              # repository.  Not sure if merging them is the right strategy or
              # not, so throwing an error for now
              raise TransferConstraintError.new(top_container.uri => "Top Container barcode '#{top_container.barcode}' already in use in target repository")
            end

            top_container.transfer_to_repository(repository, transfer_group + [self]) # i guess we always add self just in case. dups are uniqed out.
          else
            # Already transferred
          end
        else
          # something outside the graph is linked to it, add it to the list and we'll clone after transfer
          tc_id = tc_rel[:top_container_id]
          containers_to_clone[tc_id] ||= []
          containers_to_clone[tc_id] <<  tc_rel[:sub_container_id]
        end
      end
    end

    ## Transfer the current record
    super

    ## Clone the top containers that we marked for cloning
    containers_to_clone.each do |tc_to_clone, sces|
      # we copy the TC to be cloned
      hash = TopContainer.to_jsonmodel(tc_to_clone).to_hash(:trusted)

      # we make the TC in the new repo context
      RequestContext.open(:repo_id => repository.id) do
        tc = nil

        # but first lets check if this exists already by barcode
        if hash["barcode"]
          tc = TopContainer.for_barcode(hash["barcode"])
        end

        # not found, we make the clone
        unless tc
          tc = TopContainer.create_from_json(JSONModel(:top_container).from_hash(hash),
                                             :repo_id => repository.id)
        end

        # now we linke the clone to all the sub_containers
        sces.each do |sc|
          # the record is broken now, so we have to shuck it in the backdoor
          DB.open do |db|
            db[:top_container_link_rlshp].insert(:top_container_id => tc.id,
                                                 :system_mtime => Time.now,
                                                 :user_mtime => Time.now,
                                                 :sub_container_id => sc)
          end
        end
      end
    end

    ## Clone any required events and assessments in the new repository
    RequestContext.open(:repo_id => repository.id) do
      # Events
      events_to_clone.each do |to_clone|
        event = to_clone[:event].to_hash(:trusted).
                merge('linked_records' => [{
                                             'ref' => self.uri,
                                             'role' => to_clone[:role]
                                           }])

        Event.create_from_json(JSONModel(:event).from_hash(event),
                               :repo_id => repository.id)
      end

      # Assessments
      assessments_to_clone.each do |to_clone|
        assessment = to_clone[:assessment].to_hash(:trusted).
                       merge('records' => [{
                                             'ref' => self.uri,
                                           }])

        # Note: we use JSONModel#new here and not from_hash because we want to
        # keep the readonly attribute (like attribute labels).  The clone needs
        # access to those for the sake of cross-repository attribute matching.
        Assessment.clone_from_json(JSONModel(:assessment).new(assessment),
                                   :repo_id => repository.id)
      end
    end
  end
end
