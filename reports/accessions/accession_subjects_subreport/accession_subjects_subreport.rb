class AccessionSubjectsSubreport < AbstractSubreport

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query
    db[:subject_rlshp]
      .join(:subject, :id => :subject_id)
      .filter(:accession_id => @accession_id)
      .select(Sequel.as(:subject__title, :term),
              Sequel.as(Sequel.lit("GetTermType(subject.id)"), :type),
              Sequel.as(Sequel.lit("GetEnumValue(subject.source_id)"), :source))
  end

end
