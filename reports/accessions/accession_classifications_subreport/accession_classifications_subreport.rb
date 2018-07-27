class AccessionClassificationsSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query_string
    "select
      classification.identifier,
      classification.title,
      classification_term.identifier as term_identifier,
      classification_term.title as term_title
    from
      classification_rlshp
        left outer join classification on classification.id
          = classification_rlshp.classification_id
        left outer join classification_term on classification_term.id
          = classification_rlshp.classification_term_id
    where accession_id = #{db.literal(@accession_id)}"
  end

end
