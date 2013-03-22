class ArchivesSpaceService < Sinatra::Base

  helpers do
    include ReportHelper::ResponseHelpers
  end

  Endpoint.get('/reports/unprocessed_accessions')
  .description("Report on unprocessed accessions")
  .params(Endpoint.report_formats)
  .permissions([])
  .returns([200, "report"]) \
  do
    report_response(UnprocessedAccessionsReport.new, params[:format])
  end

  Endpoint.get('/reports/created_accessions')
  .description("Report on accessions created within a date range")
  .params(["from",
           DateTime,
           "The start of report range"],
          ["to",
           DateTime,
           "The start of report range"],
          Endpoint.report_formats)
  .permissions([])
  .returns([200, "report"]) \
  do
    report_response(CreatedAccessionsReport.new(params[:from], params[:to]), params[:format])
  end

end
