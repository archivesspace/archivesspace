module CustomField

	@@registered_fields ||= {}
	@@subreport_classes ||= {}
	
	def self.register_field(record_type, field_name, data_type, options)
		@@registered_fields[record_type] ||= {:fields => [], :subreports => []}
		info = options
		info[:name] = field_name
		info[:data_type] = data_type.to_s
		@@registered_fields[record_type][:fields].push(info)
	end

	def self.register_subreport(subreport, field_name, record_types, options)
		if @@subreport_classes.has_key?(subreport.code)
			Log.warn("Subreport with code '#{subreport.code}' already registered")
		end
		@@subreport_classes[subreport.code] = subreport
		record_types.each do |record_type|
			@@registered_fields[record_type] ||= {:fields => [], :subreports => []}
			info = options
			info[:name] = field_name
			info[:code] = subreport.code
			@@registered_fields[record_type][:subreports].push(info)
		end
	end

	def self.registered_fields
		@@registered_fields
	end

	def self.check_valid_record_type(record_type)
		data = @@registered_fields[record_type]
		raise "Invalid record type: #{record_type}" unless data
	end

	def self.fields_for(record_type)
		record_fields = @@registered_fields[record_type][:fields]
		global_fields = @@registered_fields['global'][:fields]
		record_fields + global_fields
	end

	def self.subreports_for(record_type)
		@@registered_fields[record_type][:subreports]
	end

	def self.subreport_class(code)
		@@subreport_classes[code]
	end

	def self.get_field_by_name(record_type, field_name)
		fields_for(record_type).each do |field|
			if field[:name] == field_name.to_s
				return field
			end
		end
		nil
	end

	module Mixin

		def self.included(base)
			base.extend(ClassMethods)
		end

		module ClassMethods

			def register_subreport(field_name, record_types, options = {})
				CustomField.register_subreport(self, field_name, record_types,
					options)
			end

			def register_field(record_type, field_name, data_type, options = {})
				CustomField.register_field(record_type, field_name, data_type,
					options)
			end

		end
	end

end