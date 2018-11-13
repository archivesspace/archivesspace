class AccessionLinkedAccessionsSubreport < AbstractSubreport

  register_subreport('interrelated_accession', ['accession'])

  def initialize(parent_report, accession_id)
    super(parent_report)
    @accession_id = accession_id
  end

  def query_string
    "select
      accession0.identifier as id0,
      related_accession_rlshp.relator_id as relator,
      accession1.identifier as id1,
      jsonmodel_type as model
    from related_accession_rlshp
      join accession as accession0 on accession_id_0 = accession0.id
      join accession as accession1 on accession_id_1 = accession1.id
    where accession_id_0 = #{db.literal(@accession_id)}
      or accession_id_1 = #{db.literal(@accession_id)}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [:relator])
    ReportUtils.fix_identifier_format(row, :id0)
    ReportUtils.fix_identifier_format(row, :id1)
    relator = I18n.t("#{row[:model]}.#{row[:relator]}")
    row[:relationship_type] = "#{row[:id0]} #{relator} #{row[:id1]}"
    row.delete(:id0)
    row.delete(:id1)
    row.delete(:relator)
    row.delete(:model)
  end

  def self.field_name
    'interrelated_accession'
  end
end
