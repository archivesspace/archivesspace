class DigitalObjectComponentFileVersionsSubreport < AbstractSubreport

  register_subreport('file_version', ['digital_object_component'])

  def initialize(parent_report, component_id)
    super(parent_report)
    @component_id = component_id
  end

  def query_string
    "select
      file_uri as uri,
      use_statement_id as use_statement
    from file_version
    where digital_object_component_id = #{db.literal(@component_id)}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:use_statement])
  end

  def self.field_name
    'file_version'
  end

end
