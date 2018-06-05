class AccessionClassificationsSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query
    db[:classification_rlshp]
      .left_outer_join(:classification, :classification__id => :classification_rlshp__classification_id)
      .left_outer_join(:classification_term, :classification_term__id => :classification_rlshp__classification_term_id)
      .filter(:accession_id => @accession_id)
      .select(Sequel.as(:classification__identifier, :classification_identifier),
              Sequel.as(:classification__title, :classification_title),
              Sequel.as(:classification_term__identifier, :classification_term_identifier),
              Sequel.as(:classification_term__title, :classification_term_title))
  end

end
