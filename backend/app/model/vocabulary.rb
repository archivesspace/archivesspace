class Vocabulary < Sequel::Model(:vocabularies)
  plugin :validation_helpers
  include ASModel

  one_to_many :subjects
  one_to_many :terms, :key => :vocab_id

  jsonmodel_hint(:the_property => :terms,
                 :contains_records_of_type => :term,
                 :corresponding_to_association  => :terms,
                 :always_resolve => true)

  def self.set(params)
    self.where(params)
  end

end
