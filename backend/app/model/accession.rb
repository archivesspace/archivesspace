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

  enable_suppression
  set_model_scope :repository

  def self.records_matching(query, max)
    self.this_repo.filter(:suppressed => 0).
         where(Sequel.like(Sequel.function(:lower, :title),
                           "#{query}%".downcase)).first(max)
  end


  def set_suppressed(val)
    self.suppressed = val ? 1 : 0
    save

    EventAccessionLink.filter(:accession_id => self.id).each do |link|
      link.event.set_suppressed(true)
    end

    val
  end

end
