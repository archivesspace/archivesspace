class ClassificationSubreport < AbstractSubreport

	register_subreport('classification', ['accession', 'resource'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		@id_type = parent_custom_report.record_type
		@id = id
	end

	def query_string
		"select
			ifnull(classification.identifier, root_record.identifier)
				as identifier,
		    ifnull(classification_term.title, classification.title)
				as title,
		    ifnull(classification_term.description,
				classification.description) as description,
			classification_term.id
		from classification_rlshp
			left outer join classification
				on classification_rlshp.classification_id
		        = classification.id
		        
			left outer join classification_term
				on classification_term.id
		        = classification_rlshp.classification_term_id
			
		    left outer join classification as root_record
				on root_record.id = classification_term.root_record_id

		where classification_rlshp.#{@id_type}_id = #{db.literal(@id)}"
	end

	def fix_row(row)
		ReportUtils.fix_boolean_fields(row, [:boolean_1, :boolean_2, :boolean_3])
		ReportUtils.fix_decimal_format(row, [:real_1, :real_2, :real_3])
		get_full_identifier(row)
	end

	def get_full_identifier(row)
		if row[:id]
			full_id_parts = [row[:identifier]] + get_term_identifier(row[:id])
			row[:identifier] = full_id_parts.join('/')
			row.delete(:id)
		end
	end

	def get_term_identifier(term_id)
		return [] unless term_id
		term_data = db.fetch("select parent_id, identifier
			from classification_term where id = #{db.literal(term_id)}")
		parent_id = ''
		identifier = ''
		term_data.each do |term|
			parent_id = term[:parent_id]
			identifier = term[:identifier]
		end
		get_term_identifier(parent_id) + [identifier]
	end

	def self.field_name
		'classification'
	end
end