class ArchivalObject < Sequel::Model(:archival_objects)
  plugin :validation_helpers
  include ASModel

  def children
    ArchivalObject.db[:collection_tree].
                   filter(:parent_id => self.id).
                   select(:child_id).map do |child_id|
      ArchivalObject[child_id[:child_id]]
    end
  end


  def validate
    super
    validates_unique([:id_0, :id_1, :id_2, :id_3],
                     :message => "That ID is already in use")
    validates_presence(:id_0, :message => "You must provide an archival object ID")
  end
end
