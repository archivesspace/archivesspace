class MetadataRightsDeclaration < Sequel::Model(:metadata_rights_declaration)
  include ASModel

  corresponds_to JSONModel(:metadata_rights_declaration)

  set_model_scope :global
end
