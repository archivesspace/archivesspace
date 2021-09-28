class StructuredDateSubreport < AbstractSubreport

  # we don't register types because this is a sub-subreport
  register_subreport('structured_date', [])

  def initialize(parent_report, id)
    super(parent_report)
    @id_type = parent_report.record_type
    @id = id
  end

  def query_string
    "select
      date_type_structured as date_type,
			date_certainty_id as certainty,
			date_expression as expression,
			date_standardized as standardized,
			date_standardized_type_id as standardized_type,
			begin_date_expression as begin_expression,
			begin_date_standardized as begin_standardized,
			begin_date_standardized_type_id as begin_standardized_type,
			end_date_expression as end_expression,
			end_date_standardized as end_standardized,
			end_date_standardized_type_id as end_standardized_type,
			date_era_id as era,
			date_calendar_id as calendar
		from structured_date_label sdl
    left outer join structured_date_single sds
      on sdl.id = sds.structured_date_label_id
    left outer join structured_date_range sdr
      on sdl.id = sdr.structured_date_label_id
		where sdl.#{@id_type}_id = #{db.literal(@id)}"
  end

  def fix_row(row)
    ReportUtils.get_enum_values(row, [
      :certainty,
      :standardized_type,
      :begin_standardized_type,
      :end_standardized_type,
      :era,
      :calendar
    ])
  end

  def self.field_name
    'structured_date'
  end
end
