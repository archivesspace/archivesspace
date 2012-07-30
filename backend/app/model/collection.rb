class Collection < Sequel::Model(:collections)
  plugin :validation_helpers
  include ASModel

  def link(opts)
    now = Time.now
    Collection.db[:collection_tree].
               insert(:parent_id => opts[:parent],
                      :child_id => opts[:child],
                      :collection_id => self.id,
                      :create_time => now,
                      :last_modified => now)
  end


end
