require_relative 'relationships'

module Classifications
  def self.included(base)
    base.include(Relationships)
    base.define_relationship(:name => :classification,
                             :json_property => 'classifications',
                             :contains_references_to_types => proc {[Classification,
                                                                     ClassificationTerm]})
  end
end
