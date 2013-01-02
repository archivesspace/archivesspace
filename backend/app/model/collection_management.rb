require_relative 'relationships'

class CollectionManagement < Sequel::Model(:collection_management)
  include ASModel
  include Relationships

  set_model_scope :repository
  corresponds_to JSONModel(:collection_management)

  define_relationship(:name => :link,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource, DigitalObject]})
end
