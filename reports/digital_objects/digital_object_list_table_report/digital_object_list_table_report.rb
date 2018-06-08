class DigitalObjectListTableReport < AbstractReport

  register_report

  def query
    db.fetch(query_string)
  end

  def query_string
    "select
      digital_object.digital_object_id as identifier,
      digital_object.title as record_title,
      digital_object.digital_object_type_id as object_type,
      GetDigitalObjectDateExpression(digital_object.id) as date_expression,
      group_concat(distinct resource.identifier separator ',,,') as resource_identifier
    from digital_object

      left outer join instance_do_link_rlshp
        on instance_do_link_rlshp.digital_object_id = digital_object.id

      left outer join instance
        on instance.id = instance_do_link_rlshp.instance_id

      left outer join archival_object
        on archival_object.id = instance.archival_object_id

      left outer join resource
        on resource.id = instance.resource_id
          or resource.id = archival_object.root_record_id

    where digital_object.repo_id = #{@repo_id}
    group by digital_object.id"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:object_type])
    ReportUtils.fix_identifier_format(row, :resource_identifier) if row[:resource_identifier]
  end

  def page_break
    false
  end

  def identifier_field
    :record_title
  end
end
