class DigitalObjectFileVersionsListSubreport < AbstractSubreport

  def initialize(parent_report, digital_object_id)
    super(parent_report)
    @digital_object_id = digital_object_id
  end

  def query
    db.fetch(query_string)
  end

  def query_string
    "select
      file_uri as uri,
      value as use_statement,
      component_id as component_identifier,
      ifnull(title, display_string) as component_title
    from file_version left outer join digital_object_component
      on digital_object_component_id = digital_object_component.id
      join enumeration_value on use_statement_id = enumeration_value.id
    where digital_object_id = #{@digital_object_id}
      or root_record_id = #{@digital_object_id}"
  end

end
