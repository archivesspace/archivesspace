class LocationResourcesContainersSubreport < AbstractSubreport

	def initialize(parent_report, location_id, resource_id)
		super(parent_report)
		@location_id = location_id
		@resource_id = resource_id
	end

	def query_string
		"select distinct
			top_container.type_id as type,
			top_container.indicator,
			top_container.barcode as top_container_barcode,
			profiles.container_profile
		from top_container_housed_at_rlshp

			left outer join
			(select
				top_container_profile_rlshp.top_container_id as id,
				group_concat(container_profile.name separator '; ')
					as container_profile
			from top_container_profile_rlshp, container_profile
			where top_container_profile_rlshp.container_profile_id
				= container_profile.id
			group by top_container_profile_rlshp.top_container_id)
			as profiles
				on profiles.id = top_container_housed_at_rlshp.top_container_id
			
			join top_container on top_container.id
				= top_container_housed_at_rlshp.top_container_id
			
			join top_container_link_rlshp on top_container.id
				= top_container_link_rlshp.top_container_id
				
			join sub_container on sub_container.id
				= top_container_link_rlshp.sub_container_id
				
			join instance on instance.id = sub_container.instance_id
			
			left outer join archival_object on archival_object.id
				= instance.archival_object_id
			
		where top_container_housed_at_rlshp.location_id
			= #{db.literal(@location_id)}
			and (instance.resource_id = #{db.literal(@resource_id)}
			or archival_object.root_record_id = #{db.literal(@resource_id)})"
	end

	def fix_row(row)
		ReportUtils.get_enum_values(row, [:type])
		ReportUtils.fix_container_indicator(row)
	end

end