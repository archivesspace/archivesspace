class ClassificationTermSubreport < AbstractSubreport
	register_subreport('classification_term', ['classification'])

	attr_accessor :subreports

	def initialize(parent, classification_id, parent_term = nil)
		super(parent)
		@subreports = parent.subreports
		@classification_id = classification_id
		@parent_term = parent_term
	end

	def query_string
		parent_condition = if @parent_term
			"parent_id = #{db.literal(@parent_term)}"
		else
			"parent_id is null"
		end
		"select
			id,
			identifier,
			title,
			description
		from classification_term
		where root_record_id = #{db.literal(@classification_id)}
			and #{parent_condition}"
	end

	def fix_row(row)
		@subreports.each do |subreport|
			if subreport == self.class
				row[:classification_term] = subreport.new(
					self, @classification_id, row[:id]).get_content
			else
				row[subreport.field_name.to_sym] = subreport.new(
					self, row[:id]).get_content
			end
		end
		row.delete(:id)
	end

	def record_type
		'classification_term'
	end

	def self.field_name
		'classification_term'
	end
end