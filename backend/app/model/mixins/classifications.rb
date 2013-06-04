require_relative 'relationships'

module Classifications
  def self.included(base)
    base.include(Relationships)
    base.define_relationship(:name => :classification,
                             :json_property => 'classification',
                             :contains_references_to_types => proc {[Classification,
                                                                     ClassificationTerm]},
                             :is_array => false)
  end
end
