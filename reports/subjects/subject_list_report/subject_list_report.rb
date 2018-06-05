class SubjectListReport < AbstractReport

  register_report

  def query
    db[:subject]
      .join(:enumeration_value, :id => :source_id)
      .select(Sequel.as(:subject__title, :subject_title),
              Sequel.as(Sequel.lit('GetTermType(subject.id)'), :term_type),
              Sequel.as(:enumeration_value__value, :source))
  end

  def identifier_field
    :subject_title
  end

  def page_break
    false
  end
end
