class Accession < Sequel::Model(:accession)
  plugin :validation_helpers
  include ASModel
  include Identifiers
  include Extents
  include Subjects
  include Dates
  include ExternalDocuments
  include RightsStatements
end
