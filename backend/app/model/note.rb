require_relative 'note_persistent_id'

class Note < Sequel::Model(:note)
  include ASModel
  include Publishable

  set_model_scope :global

  one_to_many :note_persistent_id

  def add_persistent_ids(persistent_ids, parent_id, parent_type)
    persistent_ids.each do |id|
      add_note_persistent_id(:persistent_id => id,
                             :parent_id => parent_id,
                             :parent_type => parent_type)
    end
  end

end
