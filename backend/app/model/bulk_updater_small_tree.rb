class BulkUpdaterSmallTree

  def self.for_resource(resource_id)
    Resource.get_or_die(resource_id).bulk_updater_quick_tree
  end

end
