class Extent < Sequel::Model(:extents)
  include ASModel

  plugin :validation_helpers

  many_to_one :accession
  many_to_one :resource
  many_to_one :archival_object

end
