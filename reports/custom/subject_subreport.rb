class SubjectSubreport < AbstractSubreport

	register_subreport('subject', ['accession', 'archival_object',
		'digital_object', 'digital_object_component', 'resource'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
    "select
      subject.title as term,
      group_concat(distinct term.term_type_id separator ', ') as type,
      subject.source_id as source,
      subject.authority_id as authority,
      subject.scope_note
    from subject_rlshp
      join subject
        on subject.id = subject_rlshp.subject_id
      left outer join subject_term
        on subject_term.subject_id = subject.id
      left outer join term
        on subject_term.term_id = term.id
    where subject_rlshp.#{@id_type}_id = #{db.literal(@id)}
    group by subject.id"
  end

  def fix_row(row)
		ReportUtils.get_enum_values(row, [:type, :source, :authority])
	end

	def self.field_name
		'subject'
	end

end