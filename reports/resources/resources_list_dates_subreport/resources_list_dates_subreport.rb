class ResourcesListDatesSubreport < AbstractSubreport
	def initialize(parent_report, id)
		super(parent_report)
		@date_subreport = DateSubreport.new(parent_report, id)
	end
	
	def query_string
		@date_subreport.query_string
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:label])
		date = [row[:begin], row[:end]].compact.join(' - ')
		date = nil if date.empty?
		date = [date, row[:expression]].compact.join(', ')
		date = nil if date.empty?
		date = [row[:label], date].compact.join(': ')
		row.clear
		row[:_date] = date
	end
end