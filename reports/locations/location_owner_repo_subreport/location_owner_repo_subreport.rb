class LocationOwnerRepoSubreport < AbstractSubreport
	register_subreport('owner_repo', ['location'],
		:translation => 'location.owner_repo')

	def initialize(parent_report, location_id)
		super(parent_report)
		@location_id = location_id
	end

	def query_string
		"select 
			repository.name as _name
		from owner_repo_rlshp, repository
		where owner_repo_rlshp.repository_id = repository.id
			and location_id = #{db.literal(@location_id)}"
	end

	def self.field_name
		'owner_repo'
	end
end