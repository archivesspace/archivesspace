class DigitalObjectFileVersionsListSubreport < AbstractSubreport

  register_subreport('file_version', ['digital_object'])

  def initialize(parent_report, digital_object_id)
    super(parent_report)
    @digital_object_id = digital_object_id
  end

  def query_string
    "select
      file_uri as 'file_uri',
      digital_object.title as 'digital_object_title',
      digital_object_component.title as 'digital_object_component_title'
    from file_version 
    left outer join digital_object
      on file_version.digital_object_id = digital_object.id
    left outer join digital_object_component on file_version.digital_object_component_id = digital_object_component.id
    where digital_object.id = #{db.literal(@digital_object_id)}
    or root_record_id = #{db.literal(@digital_object_id)}"
  end

  def self.field_name
    'file_version'
  end

end
