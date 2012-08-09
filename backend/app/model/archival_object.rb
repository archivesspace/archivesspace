class ArchivalObject < Sequel::Model(:archival_objects)
  plugin :validation_helpers
  include ASModel
  include Identifiers

  many_to_many :subjects

  def children
    ArchivalObject.db[:collection_tree].
                   filter(:parent_id => self.id).
                   select(:child_id).map do |child_id|
      ArchivalObject[child_id[:child_id]]
    end
  end
end
