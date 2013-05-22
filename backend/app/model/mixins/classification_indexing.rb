# Each classification term needs to track the names of all nodes between the
# root of the tree and itself.  Should a node further up change, we need to
# trigger reindexing of the current node too.
#
# Not pretty, but them's the breaks.  This could be done much more efficiently,
# but I'm assuming classification trees generally won't be more than a few
# levels deep, and not updated often.  Maybe famous last words :)

module ClassificationIndexing

  def reindex_children(top = false)
    if !top
      self.class.fire_update(self.class.to_jsonmodel(self), self)
      self.class.update_mtime_for_ids([self.id])
    end

    trigger_reindex_of_dependants

    self.children.each do |child|
      child.reindex_children
    end
  end

end
