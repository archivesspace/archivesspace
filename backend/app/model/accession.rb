class Accession < Sequel::Model(:accessions)
  plugin :validation_helpers
  include ASModel
  include Identifiers
  include Extents
  include Subjects
  include Dates
  include ExternalDocuments
end
