class LinkedArchivalObjectSubreport < AbstractSubreport

	@@link_tables ||= {'assessment' => 'assessment_rlshp',
		'subject' => 'subject_rlshp', 'rights_statement' => 'rights_statement',
		'agent' => 'linked_agents_rlshp', 'event' => 'event_link_rlshp',
		'resource' => 'resource'
	}

	@@extra_fields ||= {'agent' => [{:field => 'role_id as role',
		:type => 'Enum'}, {:field => 'relator_id as relator', :type => 'Enum'}],
		'event' => [{:field => 'role_id as role', :type => 'Enum'}]
	}

	register_subreport('archival_object', @@link_tables.keys)

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

		from_string = "archival_object, #{@link_table}"
		where_string = "#{@link_table}.#{@id_field} = #{db.literal(@id)} and archival_object.root_record_id = resource.id and archival_object.repo_id = #{db.literal(@repo_id)}"
		unless @link_table == 'resource'
			from_string += ", resource"
			where_string += " and #{@link_table}.archival_object_id = archival_object.id"
		end

		fields = ['archival_object.component_id',
							'archival_object.title',
							'archival_object.ref_id',
							'archival_object.level_id as level',
							'resource.identifier as root_record']
		fields += @link_fields.collect {|f| "#{@link_table}.#{f[:field]}"}
		"select
			#{fields.join(', ')}
		from #{from_string}
		where #{where_string}"
	end

	def fix_row(row)
		ReportUtils.fix_identifier_format(row, :root_record)
		ReportUtils.get_enum_values(row, [:level])
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
		'archival_object'
	end

end