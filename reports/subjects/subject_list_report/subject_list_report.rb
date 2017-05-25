class SubjectListReport < AbstractReport

  register_report

  def template
    'generic_listing.erb'
  end

  def headers
    ['subject_title', 'subject_term_type', 'subject_source']
  end

  def query
    db[:subject]
      .join(:enumeration_value, :id => :source_id)
      .select(Sequel.as(:subject__id, :subject_id),
              Sequel.as(:subject__title, :subject_title),
              Sequel.as(:subject__source_id, :subject_source_id),
              Sequel.as(Sequel.lit('GetTermType(subject.id)'), :subject_term_type),
              Sequel.as(:enumeration_value__value, :subject_source))
  end
end
