require_relative '../model/reports/report_manager'
require_relative '../lib/static_asset_finder'

class ArchivesSpaceService < Sinatra::Base

  include ReportHelper::ResponseHelpers


  ReportManager.registered_reports.each do |uri_suffix, opts|

    Endpoint.get("/repositories/:repo_id/reports/#{uri_suffix}")
    .description(opts[:description])
    .params(*(opts[:params] << ReportHelper.report_formats << ["repo_id", :repo_id]))
    .permissions([])
    .returns([200, "report"]) \
    do
      report_response(opts[:model].new(params), params[:format])
    end

  end

  Endpoint.get('/reports')
  .description('List all reports')
  .permissions([])
  .returns([200, "report list in json"]) \
    do
    json_response({
                    :reports => ReportManager.registered_reports,
                    :formats => ReportHelper.allowed_report_formats
                  })
  end


  Endpoint.get('/reports/static/*')
  .description('Get a static asset for a report')
  .params(["splat", String, "The requested asset"])
  .permissions([])
  .returns([200, "the asset"]) \
  do
    send_file(StaticAssetFinder.new(File.join("reports", "static")).find(params[:splat][0]))
  end


end
