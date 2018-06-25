module CustomField

	@@registered_fields ||= {}
	@@subreport_classes ||= {}
	
	def self.register_field(record_type, field_name, data_type, sortable)
		@@registered_fields[record_type] ||= {:fields => [], :subreports => []}
		info = {:name => field_name, :data_type => data_type.to_s,
			:sortable => sortable}
		@@registered_fields[record_type][:fields].push(info)
	end

	def self.register_subreport(subreport, field_name, record_types)
		record_types.each do |record_type|
			@@registered_fields[record_type] ||= {:fields => [], :subreports => []}
			info = {:name => field_name, :code => subreport.code}
			@@registered_fields[record_type][:subreports].push(info)
			@@subreport_classes[subreport.code] = subreport
		end
	end

	def self.registered_fields
		@@registered_fields
	end

	def self.subreport_class(code)
		@@subreport_classes[code]
	end

	def self.get_field_by_name(record_type, field_name)
    	@@registered_fields[record_type][:fields].each do |field|
    		if field[:name] == field_name
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

      def register_subreport(field_name, record_types)
        CustomField.register_subreport(self, field_name, record_types)
      end

      def register_field(record_type, field_name, data_type, sortable = false)
      	CustomField.register_field(record_type, field_name, data_type, sortable)
      end
    end
  end

end