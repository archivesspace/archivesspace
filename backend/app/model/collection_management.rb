class CollectionManagement < Sequel::Model(:collection_management)
  include ASModel
  include ExternalIDs

  set_model_scope :repository
  corresponds_to JSONModel(:collection_management)

end
