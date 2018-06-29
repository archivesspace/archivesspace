class FakeSubreport < AbstractSubreport

	# register_subreport('FAKE', ['accession',
	# 	'archival_object', 'resource', 'subject', 'digital_object',
	# 	'digital_object_component', 'agent',
	# 	'event', 'rights_statement'])

	def initialize(parent_custom_report, id)
		super(parent_custom_report)
	end

	def query
		raise "I don't work!"
	end

	def self.field_name
		'FAKE'
	end
end