class Vocabulary < Sequel::Model(:vocabulary)
  include ASModel
  corresponds_to JSONModel(:vocabulary)

  set_model_scope :global

  one_to_many :subject
  one_to_many :term, :key => :vocab_id

  def_nested_record(:the_property => :terms,
                    :contains_records_of_type => :term,
                    :corresponding_to_association  => :term,
                    :always_resolve => true)

  def self.set(params)
    self.where(params)
  end

end
