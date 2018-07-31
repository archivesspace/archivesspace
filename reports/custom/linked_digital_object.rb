class LinkedDigitalObjectSubreport < AbstractSubreport

	@@link_tables ||= {'assessment' => 'assessment_rlshp',
		'subject' => 'subject_rlshp', 'rights_statement' => 'rights_statement',
		'agent' => 'linked_agents_rlshp', 'event' => 'event_link_rlshp'
	}

	@@extra_fields ||= {'agent' => [{:field => 'role_id as role',
		:type => 'Enum'}, {:field => 'relator_id as relator', :type => 'Enum'}],
		'event' => [{:field => 'role_id as role', :type => 'Enum'}]
	}

	register_subreport('digital_object', @@link_tables.keys)

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		id_type = parent_custom_report.record_type
		record_type = if id_type.include?('agent')
			'agent'
		else
			id_type
		end
		@link_table = @@link_tables[record_type]
		@link_fields = @@extra_fields[record_type] || []
		@id_field = @link_table == record_type ? 'id' : "#{id_type}_id"
		@id = id
	end

	def query_string
		fields = ['digital_object.digital_object_id', 'digital_object.title']
		fields += @link_fields.collect {|f| "#{@link_table}.#{f[:field]}"}
		"select
			#{fields.join(', ')}
		from digital_object, #{@link_table}
		where #{@link_table}.#{@id_field} = #{db.literal(@id)}
		and #{@link_table}.digital_object_id = digital_object.id
		and digital_object.repo_id = #{db.literal(@repo_id)}"
	end

	def fix_row(row)
		@link_fields.each do |field|
			field_name = field[:field].split(' ')[-1].to_sym
			case field[:type]
			when 'Enum'
				ReportUtils.get_enum_values(row, [field_name])
			when 'Boolean'
				ReportUtils.fix_boolean_fields(row, [field_name])
			when 'Decimal'
				ReportUtils.fix_decimal_format(row, [field_name])
			end
		end
	end

	def self.field_name
		'digital_object'
	end

end