class Accession < Sequel::Model(:accession)
  plugin :validation_helpers
  include ASModel
  include Identifiers
  include Extents
  include Subjects
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Deaccessions
  include Agents

  set_model_scope :repository

  def self.records_matching(query, max)
    self.where(Sequel.like(Sequel.function(:lower, :title),
                           "#{query}%".downcase)).first(max)
  end

end
