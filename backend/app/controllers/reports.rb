class ArchivesSpaceService < Sinatra::Base

  helpers do
    include ReportHelper::ResponseHelpers
  end

  ALLOWED_REPORT_FORMATS = ["json", "csv"]

  Endpoint.get('/reports/unprocessed_accessions')
  .description("Report on unprocessed accessions")
  .params(["format",
           String,
           "The format to render the report (one of: #{ALLOWED_REPORT_FORMATS.join(", ")})",
           :validation => ["Must be one of #{ALLOWED_REPORT_FORMATS.join(", ")}",
                           ->(v){ ALLOWED_REPORT_FORMATS.include?(v) }]])
  .permissions([])
  .returns([200, "report"]) \
  do
    report = UnprocessedAccessionsReport.new

    report_response(report, params[:format])
  end

end
