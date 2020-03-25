module ReindexTopContainers

  def reindex_top_containers(extra_ids = [])

    if !DB.respond_to?(:supports_join_updates?) || !DB.supports_join_updates?
      Log.warn("Invoking slow path for reindexing top containers")
      return reindex_top_containers_by_any_means_necessary(extra_ids)
    end

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
    elsif root_record.is_a?(ArchivalObject)
      Log.warn("Invoking slow path for reindexing top containers")
      reindex_top_containers_by_any_means_necessary(extra_ids)
    elsif root_record.is_a?(Accession)
      accession_instance_root_record_update(root_record.id)
    end

  end


  # Slow path for weird data or DBs that don't support updates on joins (like derby/h2)
  def reindex_top_containers_by_any_means_necessary(extra_ids)
    # Find any relationships between a top container and any instance within the current tree.
    root_record = if self.class == ArchivalObject
                    self.class.root_model[self.root_record_id]
                  else
                    self
                  end
    tree_object_graph = root_record.object_graph
    top_container_link_rlshp = SubContainer.find_relationship(:top_container_link)
    relationship_ids = tree_object_graph.ids_for(top_container_link_rlshp)

    # Update the mtimes of each top container
    DB.open do |db|
      top_container_ids = db[:top_container_link_rlshp].filter(:id => relationship_ids).map(:top_container_id)
      top_container_ids.concat(extra_ids)
      TopContainer.filter(:id => top_container_ids).update(:system_mtime => Time.now)
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
