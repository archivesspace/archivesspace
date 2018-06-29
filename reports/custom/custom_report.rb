class CustomReport < AbstractReport

	register_report(
    params: [['custom_data', 'CustomFields',
    	'Fields to include in custom report.', CustomField.registered_fields]]
  )

  attr_accessor :record_type

  def initialize(params, job, db)
    super    

    data_file = ''
    job.job_files.each do |file|
    	data_file += file.file_path
    end

    template = ASUtils.json_parse(IO.read(data_file))

    @record_type = template['custom_record_type']
    info[:custom_record_type] = I18n.t("#{@record_type}._plural",
    	:default => @record_type)

    @fields = []

    @boolean_fields = []
    @enum_fields = []
    @decimal_fields = []

    table = @record_type == 'agent' ? 'agent_person'.to_sym : @record_type.to_sym
    @possible_fields = db[table].columns.collect {|c| c.to_s}

    unless @possible_fields.include? 'repo_id'
    	@conditions = ["1 = 1"]
    else
    	@conditions = ["repo_id = #{@repo_id}"]
    end


    CustomField.fields_for(@record_type).each do |field|
    	field_name = field[:name]

    	next unless ASUtils.present?(template['fields'][field_name])

    	begin
    		@fields.push(field) if template['fields'][field_name]['include']
    	rescue NoMethodError => e
    		
    	end

    	if (ASUtils.present?(template['fields'][field_name]['narrow_by'])) &&
    		(template['fields'][field_name]['narrow_by'])

    		begin
    			case field[:data_type]
	    		when 'Date'
	  				date_narrow(template, field_name)
	  			when 'AgentType'
	  				agent_type_narrow(template, field_name)
	  			when 'Boolean'
	  				boolean_narrow(template, field_name)
	  			when 'Enum'
	  				enum_narrow(template, field)
	  			when 'User'
	  				user_narrow(template, field_name)
		  		end
	  		rescue Exception => e
  				raise "Selected to narrow results by #{field_name} but missing values."
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

		CustomField.subreports_for(@record_type).each do |subreport|
			field_name = subreport[:name]
			begin
				if template['subreports'][field_name]['include']
					subreport_class = CustomField.subreport_class(subreport[:code])
					@subreports.push(subreport_class)
				end
			rescue NoMethodError => e
				
			end
		end

		@order_field = template['sort_by'] == '' ? nil : template['sort_by']
		if @order_field
			info['sorted_by'] = special_translation(@order_field, nil) || @order_field
			field = CustomField.get_field_by_name(@record_type, @order_field)
			@order_field += '_id' if field[:data_type] == 'Enum'
			@order_field = nil unless @possible_fields.include? @order_field
		end
  end

  def query
  	results = unless record_type == 'agent'
					  		db.fetch(query_string)
					  	else
					  		db.fetch(agent_query_string)
					  	end
		info[:total_count] = results.count
		results
  end

	def query_string(fields = nil)

		fields ||= select_fields

		order_by = @order_field ? "order by #{@order_field}" : ''
		where = @conditions.collect {|item| "(#{item})"}.join(' and ')

		"select id#{fields}
		from #{@record_type}
		where #{where}
		#{order_by}"
	end

	def agent_query_string

		@agent_types ||= ['agent_family', 'agent_person', 'agent_corporate_entity',
			'agent_software']

		order_field = @order_field
		@order_field = nil

		type_field = CustomField.get_field_by_name('agent', 'type')
		include_agent_type = false
		if @fields.include?(type_field)
			include_agent_type = true
			@fields.delete(type_field)
		else
			order_field = 'type_code' if order_field == 'type'
		end

		query_parts = []
		@agent_types.each do |agent_type|
			@record_type = agent_type
			type_fields = ", '#{agent_type}' as type_code"
			if include_agent_type
				type_translation = I18n.t("agent.agent_type.#{agent_type}")
				type_translation ||= agent_type
				type_fields += ", '#{type_translation}' as type"
			end
			fields = type_fields + select_fields
			query_parts.push(query_string(fields))
		end
		"#{query_parts.join(' union ')}
		#{order_field ? "order by #{order_field}" : ''}"
	end

	def select_fields
		columns = {}
		@fields.each do |field|
			if field[:data_type] == 'Enum'
				columns["#{field[:name]}_id"] = field[:alias] || field[:name]
			elsif field[:name] == 'title'
				columns['title'] = field[:alias] || 'record_title'
			else
				columns[field[:name]] = field[:alias] || field[:name]
			end
		end
		select_fields = ''
		columns.each do |column, colum_alias|
			if @possible_fields.include? column
				select_fields += ", #{@record_type}.#{column} as #{colum_alias}"
			else
				msg = "#{@record_type} does not have field '#{column}'. Skipping."
				job.write_output(msg)
			end
		end
		select_fields
	end

	def fix_row(row)
		@record_type = row[:type_code] if record_type.include? 'agent'
		ReportUtils.fix_boolean_fields(row, @boolean_fields)
		ReportUtils.get_enum_values(row, @enum_fields)
		ReportUtils.fix_decimal_format(row, @decimal_fields)
		ReportUtils.local_times(row, [:create_time, :user_mtime])
		if @record_type == 'accession' || @record_type == 'resource'
			ReportUtils.fix_identifier_format(row) if row[:identifier]
		end
		@subreports.each do |subreport_class|
			begin
				row[subreport_class.field_name.to_sym] = subreport_class
					.new(self, row[:id]).get_content
			rescue Exception => e
				name = special_translation(@record_type, subreport_class.code)
				job.write_output("Problem with '#{name}' Subreport: #{e}")
				job.write_output("Skipping #{name} Subreport.")
			end
		end
		if record_type.include? 'agent'
			row.delete(:type_code)
		end
		row.delete(:id)
	end

	def after_tasks
		@record_type = 'agent' if record_type.include? 'agent'
	end

	def special_translation(key, subreport_code)
		if subreport_code
			subreport_name = CustomField.subreport_class(subreport_code).field_name
			I18n.t("#{subreport_name}.#{key}", :default => nil)
		else
			field = CustomField.get_field_by_name(record_type, key)
			if field
				translation_scope = field[:translation_scope] || record_type
				I18n.t("#{translation_scope}.#{key}", :default => nil)
			else
				sub_trans = I18n.t("#{key}._plural", :default => nil)
				I18n.t("#{@record_type}.#{key}", :default => sub_trans)
			end
		end
	end

	def date_narrow(template, field_name)
		return unless @possible_fields.include? field_name
		range_start = template['fields'][field_name]['range_start']
		range_end = template['fields'][field_name]['range_end']
		from = DateTime.parse(range_start).to_time.strftime(
			'%Y-%m-%d')
		to = DateTime.parse(range_end).to_time.strftime(
			'%Y-%m-%d')
		@conditions.push("#{field_name} > #{from.gsub('-', '')}")
		@conditions.push("#{field_name} < #{to.gsub('-', '')}")
		info[field_name] = "#{from} - #{to}"
	end

	def agent_type_narrow(template, field_name)
		@agent_types = template['fields'][field_name]['values']
		raise if !@agent_types || @agent_types.empty?
		info[field_name] = @agent_types.join(', ')
	end

	def boolean_narrow(template, field_name)
		return unless @possible_fields.include? field_name
		value = template['fields'][field_name]['value']
		@conditions.push("#{field_name} = #{value}")
		info[field_name] = value.to_s == 'true' ? 'Yes' : 'No'
	end

	def enum_narrow(template, field)
		field_name = field[:name]
		return unless @possible_fields.include? "#{field_name}_id"
		values = template['fields'][field_name]['values']
		raise if !values || values.empty?
		@conditions.push("#{field_name}_id in (#{values.join(', ')})")

		begin
			enum_name = field[:enum_name] || "#{@record_type}_#{field_name}"
			value_names = []
			values.each do |id|
				enum_val = EnumerationValue.get_or_die(id)
				value = enum_val.value
				value_name = I18n.t("enumerations.#{enum_name}.#{value}",
					:default => value)
				value_names.push(value_name)
			end
			info[field_name] = value_names.join(', ')		
		rescue Exception => e
			info[field_name] = values.join(', ')
		end
	end

	def user_narrow(template, field_name)
		return unless @possible_fields.include? field_name
		values = template['fields'][field_name]['values']
		raise if !values || values.empty?
		value_list = values.collect { |value| "'#{value}'" }.join(', ')
		@conditions.push("#{field_name} in (#{value_list})")
		info[field_name] = values.join(', ')
	end
end