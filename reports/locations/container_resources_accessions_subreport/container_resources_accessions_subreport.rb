class ContainerResourcesAccessionsSubreport < AbstractSubreport

  def initialize(parent_report, container_id)
    super(parent_report)
    @container_id = container_id
  end

  def query_string
    "select distinct 
      'resource' as linked_record_type,
        resource.identifier as identifier,
        resource.title as record_title 
    from
      (select sub_container_id as id
        from top_container_link_rlshp 
        where top_container_id = #{db.literal(@container_id)}) as sub_ids
        
        join sub_container on sub_ids.id = sub_container.id
        
        join instance on sub_container.instance_id = instance.id
        
        left outer join archival_object
        on instance.archival_object_id = archival_object.id
      
        join resource
        on resource.id = instance.resource_id
          or resource.id = archival_object.root_record_id
                
    union

    select
      'accession' as linked_record_type,
      identifier as identifier,
        title as record_title
    from accession
        join instance on accession.id = accession_id
        join sub_container on instance.id = instance_id
        join top_container_link_rlshp on sub_container.id = sub_container_id
    where top_container_id = #{db.literal(@container_id)}"
  end

  def fix_row(row)
    ReportUtils.fix_identifier_format(row, :identifier)
  end
end