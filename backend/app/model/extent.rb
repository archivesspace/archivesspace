class Extent < Sequel::Model(:extent)
  include ASModel
  include ActiveAssociation
  corresponds_to JSONModel(:extent)

  set_model_scope :global
  many_to_one :accession
  many_to_one :archival_object
  many_to_one :deaccession
  many_to_one :digital_object
  many_to_one :digital_object_component
  many_to_one :resource
end
