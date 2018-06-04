class ContainerResourcesAccessionsSubreport < AbstractSubreport

  def initialize(parent_report, container_id)
    super(parent_report)
    @container_id = container_id
  end

  def query
    resource_query_string = "select 'resource' as type,
  identifier as record_identifier, title as record_title from
	resource natural join
	(select distinct GetResourceIdentiferForInstance(instance_id) as identifier, repo_id from
		sub_container join top_container_link_rlshp
		on sub_container.id = sub_container_id
        join top_container on top_container_id = top_container.id
	where top_container_id = #{@container_id}) as tbl
where resource.repo_id = tbl.repo_id"

    accession_query_string = "select 'accession' as type,
  identifier as record_identifier, title as record_title from
	accession join instance on accession.id = accession_id
    join sub_container on instance.id = instance_id
    join top_container_link_rlshp on sub_container.id = sub_container_id
where top_container_id = #{@container_id}"

    db.fetch(resource_query_string).union(db.fetch(accession_query_string))
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :record_identifier)
  end
end