# Suppression filtering shared by reports and subreports.
#
# Reports only export suppressed records when the user holds the
# view_suppressed permission and has explicitly asked for them (see
# ReportsRunner), so every query joining a suppressible table needs this filter.
# Subreports inherit the setting from the report that spawned them.
module ReportSuppression

  attr_accessor :include_suppressed

  def suppressed_filter(table_name)
    include_suppressed ? '' : " AND ifnull(#{table_name}.suppressed, 0) = 0"
  end
end
