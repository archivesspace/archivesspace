require_relative '../model/reports/report_manager'

class ArchivesSpaceService < Sinatra::Base

  helpers do
    include ReportHelper::ResponseHelpers
  end

  ReportManager.registered_reports.each do |report_class, opts|

    Endpoint.get(opts[:uri])
    .description(opts[:description])
    .params(*(opts[:params] << Endpoint.report_formats))
    .permissions(opts[:permissions] || [])
    .returns([200, "report"]) \
    do
      report_response(report_class.new(params), params[:format])
    end

  end

  Endpoint.get('/reports')
  .description('List all reports')
  .permissions([])
  .returns([200, "report list in json"]) \
    do
    json_response(ReportManager.registered_reports)
  end

end
