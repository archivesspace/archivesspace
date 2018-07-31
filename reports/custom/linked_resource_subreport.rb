class LinkedResourceSubreport < AbstractSubreport

	@@link_tables ||= {'assessment' => 'assessment_rlshp',
		'deaccession' => 'deaccession', 'subject' => 'subject_rlshp',
		'classification' => 'classification_rlshp',
		'rights_statement' => 'rights_statement', 'agent' => 'linked_agents_rlshp',
		'event' => 'event_link_rlshp', 'accession' => 'spawned_rlshp',
		'archival_object' => 'archival_object'
	}

	@@extra_fields ||= {'agent' => [{:field => 'role_id as role',
		:type => 'Enum'}, {:field => 'relator_id as relator', :type => 'Enum'}],
		'event' => [{:field => 'role_id as role', :type => 'Enum'}]
	}

	register_subreport('resource', @@link_tables.keys)

	def initialize(parent_custom_report, id)
		super(parent_custom_report)

		id_type = parent_custom_report.record_type
		record_type = if id_type.include?('agent')
			'agent'
		elsif id_type.include?('classification')
			'classification'
		else
			id_type
		end
		@link_table = @@link_tables[record_type]
		@link_fields = @@extra_fields[record_type] || []
		@id_field = @link_table == record_type ? 'id' : "#{id_type}_id"
		@id = id
		if record_type == 'archival_object'
			@resource_id_field = 'root_record_id'
		else
			@resource_id_field = 'resource_id'
		end
	end

	def query_string
		fields = ['resource.identifier', 'resource.title']
		fields += @link_fields.collect {|f| "#{@link_table}.#{f[:field]}"}
		"select
			#{fields.join(', ')}
		from resource, #{@link_table}
		where #{@link_table}.#{@id_field} = #{db.literal(@id)}
		and #{@link_table}.#{@resource_id_field} = resource.id
		and resource.repo_id = #{db.literal(@repo_id)}"
	end

	def fix_row(row)
		ReportUtils.fix_identifier_format(row)
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
		'resource'
	end

end