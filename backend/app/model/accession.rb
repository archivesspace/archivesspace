class Accession < Sequel::Model(:accessions)
  plugin :validation_helpers
  include ASModel
  include Identifiers
end
