require_relative 'relationships'

class CollectionManagement < Sequel::Model(:collection_management)
  include ASModel
  corresponds_to JSONModel(:collection_management)

  include Relationships
  include ExternalIDs

  set_model_scope :repository

  define_relationship(:name => :link,
                      :json_property => 'linked_records',
                      :contains_references_to_types => proc {[Accession, Resource, DigitalObject]})
end
