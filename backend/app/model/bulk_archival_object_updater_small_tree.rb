class BulkArchivalObjectUpdaterSmallTree
  def self.for_resource(resource_id)
    Resource.get_or_die(resource_id).bulk_archival_object_updater_quick_tree
  end
end
