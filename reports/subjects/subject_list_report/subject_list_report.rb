class SubjectListReport < AbstractReport

  register_report

  def query_string
    "select
      subject.title as term,
      group_concat(distinct term.term_type_id separator ', ') as type,
      subject.source_id as source
    from subject_rlshp
      join subject
        on subject.id = subject_rlshp.subject_id
      left outer join subject_term
        on subject_term.subject_id = subject.id
      left outer join term
        on subject_term.term_id = term.id
    group by subject.id"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:type, :source])
  end

  def identifier_field
    :term
  end

  def page_break
    false
  end
end
