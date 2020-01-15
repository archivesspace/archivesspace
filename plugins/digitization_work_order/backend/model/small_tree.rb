class SmallTree

  def self.for_resource(resource_id)
    Resource.get_or_die(resource_id).quick_tree
  end

end
