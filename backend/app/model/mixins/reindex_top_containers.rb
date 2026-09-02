module ReindexTopContainers

  def reindex_top_containers(extra_ids = [])
    # Find any relationships between a top container and any instance within the current tree.
    root_record = if self.class == ArchivalObject
                    self.class.root_model[self.root_record_id]
                  else
                    self
                  end

    if !extra_ids.empty?
      TopContainer.filter(:id => extra_ids).update(:system_mtime => Time.now)
    end

    if root_record.is_a?(Resource)
      resource_instance_update(root_record.id)
      ao_instance_root_record_update(root_record.id)
    elsif root_record.is_a?(Accession)
      accession_instance_root_record_update(root_record.id)
    end
  end

  def resource_instance_update(id)
    TopContainer.linked_instance_ds.filter(
      instance__resource_id: id
    ).update(:top_container__system_mtime => Time.now)
  end

  def ao_instance_root_record_update(id)
    TopContainer.linked_instance_ds.join(
      :archival_object, :archival_object__id => :instance__archival_object_id).
      filter(:archival_object__root_record_id => id
    ).update(:top_container__system_mtime => Time.now)
  end

  def accession_instance_root_record_update(id)
    TopContainer.linked_instance_ds.filter(
      :instance__accession_id => id
    ).update(:top_container__system_mtime => Time.now)
  end

  # not defined in accession or resource
  def set_parent_and_position(*)
    super
    reindex_top_containers
  end

  def set_root(*)
    super
    reindex_top_containers
  end

  def delete
    reindex_top_containers
    super
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # we need to reindex top containers for instances about to be zapped
    # so remember the top containers we currently link to ...
    top_container_ids = instance.map {|instance|
                          # don't assume a sub_container - it might be a digital object instance
                          instance.sub_container.map {|sc| sc.related_records(:top_container_link).id}
                        }.flatten.compact

    result = super

    # ... and pass them in as extras
    reindex_top_containers(top_container_ids) unless opts[:skip_reindex_top_containers]

    result
  end

end
