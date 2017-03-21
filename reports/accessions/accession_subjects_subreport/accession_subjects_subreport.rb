class AccessionSubjectsSubreport < AbstractReport

  def template
    "accession_subjects_subreport.erb"
  end

  def query
    db[:subject_rlshp]
      .join(:subject, :id => :subject_id)
      .filter(:accession_id => @params.fetch(:accessionId))
      .select(Sequel.as(:subject__id, :subject_id),
              Sequel.as(:subject__title, :subjectTerm),
              Sequel.as(Sequel.lit("GetTermType(subject.id)"), :subjectTermType),
              Sequel.as(Sequel.lit("GetEnumValue(subject.source_id)"), :subjectSource))
  end

end
