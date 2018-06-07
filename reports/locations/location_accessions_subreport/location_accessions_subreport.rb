class LocationAccessionsSubreport < AbstractSubreport
  def initialize(parent_report, location_id)
    super(parent_report)
    @location_id = location_id
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "select
      accession.identifier as identifier,
        accession.title as title
    from 
      (select * from top_container_housed_at_rlshp
      where location_id = #{@location_id}) as top_ids

      join top_container on top_container.id = top_ids.id

      join top_container_link_rlshp
        on top_container_link_rlshp.top_container_id = top_container.id

      join sub_container
        on sub_container.id = top_container_link_rlshp.sub_container_id

      join instance on instance.id = sub_container.instance_id
        join accession on accession.id = instance.accession_id

    where accession.repo_id = #{@repo_id}"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row)
  end
end
