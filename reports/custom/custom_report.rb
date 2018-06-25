class CustomReport < AbstractReport

	include CustomField::Mixin

	register_field('accession', 'access_restrictions', 'Boolean')
	register_field('accession', 'access_restrictions_note', String)
	register_field('accession', 'accession_date', 'Date', true)
	register_field('accession', 'acquisition_type', 'Enum', true)
	register_field('accession', 'condition_description', String)
	register_field('accession', 'content_description', String)
	register_field('accession', 'disposition', String)
	register_field('accession', 'identifier', String, true)
	register_field('accession', 'general_note', String)
	register_field('accession', 'inventory', String)
	register_field('accession', 'provenance', String)
	register_field('accession', 'publish', 'Boolean')
	register_field('accession', 'resource_type', 'Enum', true)
	register_field('accession', 'restrictions_apply', 'Boolean')
	register_field('accession', 'retention_rule', String)
	register_field('accession', 'title', String, true)
	register_field('accession', 'use_restrictions', 'Boolean')
	register_field('accession', 'use_restrictions_note', String)

	register_field('resource', 'identifier', String, true)

	register_report(
    params: [['custom_data', 'CustomFields',
    	'Fields to include in custom report.', CustomField.registered_fields]]
  )

  attr_accessor :record_type

  def initialize(params, job, db)
    super

    @record_type = params['record_type']
    info[:custom_record_type] = I18n.t("#{@record_type}._plural",
    	:default => @record_type)

    data_file = ''
    job.job_files.each do |file|
    	data_file += file.file_path
    end

    custom_data = ASUtils.json_parse(IO.read(data_file))[@record_type]

    @fields = []

    @boolean_fields = []
    @enum_fields = []
    @decimal_fields = []

    # todo - some record types don't have repo_id fix
    @conditions = ["repo_id = #{@repo_id}"]

    CustomField.registered_fields[@record_type][:fields].each do |field|
    	field_name = field[:name]
    	begin
    		@fields.push(field) if custom_data['fields'][field_name]['include']
    	rescue NoMethodError => e
    		
    	end

    	if (field[:data_type] == 'Date') &&
    			(ASUtils.present?(custom_data['fields'][field_name]['narrow_by'])) &&
    			(custom_data['fields'][field_name]['narrow_by'])
  			begin
  				range_start = custom_data['fields'][field_name]['range_start']
  				range_end = custom_data['fields'][field_name]['range_end']
  				from = DateTime.parse(range_start).to_time.strftime(
  					'%Y-%m-%d %H:%M:%S')
  				to = DateTime.parse(range_end).to_time.strftime(
  					'%Y-%m-%d %H:%M:%S')
  				@conditions.push("#{field_name} > #{from.split(' ')[0].gsub('-', '')}")
  				@conditions.push("#{field_name} < #{to.split(' ')[0].gsub('-', '')}")
  			rescue Exception => e
  				raise "Selected to narrow results by #{field_name} but missing date range."
  			end
  		end
    end

    @fields.each do |field|
			case(field[:data_type])
			when 'Boolean'
				@boolean_fields.push(field[:name].to_sym)
			when 'Enum'
				@enum_fields.push(field[:name].to_sym)
			when 'Decimal'
				@decimal_fields.push(field[:name].to_sym)
			end
		end

		@subreports = []

		CustomField.registered_fields[@record_type][:subreports]
		.each do |subreport|
			field_name = subreport[:name]
			begin
				if custom_data['subreports'][field_name]['include']
					subreport_class = CustomField.subreport_class(subreport[:code])
					@subreports.push(subreport_class)
				end
			rescue NoMethodError => e
				
			end
		end

		@order_field = custom_data['sort_by'] == '' ? nil : custom_data['sort_by']
		if @order_field
			field = CustomField.get_field_by_name(@record_type, @order_field)
			@order_field += '_id' if field[:data_type] == 'Enum'
		end
  end

  def query
  	db.fetch(query_string)
  end

	def query_string
		select_fields = ''
		@fields.each do |field|
			if field[:data_type] == 'Enum'
				select_fields += ", #{field[:name]}_id as #{field[:name]}"
			elsif field[:name] == 'title'
				select_fields += ', title as record_title'
			else
				select_fields += ", #{field[:name]}"
			end
		end

		order_by = @order_field ? "order by #{@order_field}" : ''
		where = @conditions.collect {|item| "(#{item})"}.join(' and ')

		"select id#{select_fields}
		from #{@record_type}
		where #{where}
		#{order_by}"
	end

	def fix_row(row)
		ReportUtils.fix_boolean_fields(row, @boolean_fields)
		ReportUtils.get_enum_values(row, @enum_fields)
		ReportUtils.fix_decimal_format(row, @decimal_fields)
		if @record_type == 'accession' || @record_type == 'resource'
			ReportUtils.fix_identifier_format(row) if row[:identifier]
		end
		@subreports.each do |subreport_class|
			row[subreport_class.field_name.to_sym] = subreport_class
				.new(self, row[:id]).get_content
		end
		row.delete(:id)
	end

	def special_translation(key, subreport_code)
		if subreport_code
			subreport_name = CustomField.subreport_class(subreport_code).field_name
			I18n.t("#{subreport_name}.#{key}", :default => nil)
		else
			subreport_translation = I18n.t("#{key}._plural", :default => nil)
			I18n.t("#{record_type}.#{key}", :default => subreport_translation)
		end
	end
end