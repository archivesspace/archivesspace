require_relative '../model/reports/report_manager'
require_relative '../lib/static_asset_finder'

class ArchivesSpaceService < Sinatra::Base


  # this is a leftover that's here for reports utility stuff
  # Reports now live as Jobs. 

  Endpoint.get('/reports')
  .description('List all reports')
  .permissions([])
  .returns([200, "report list in json"]) \
    do
    json_response({
                    :reports => ReportManager.registered_reports,
                    :formats => ReportManager.allowed_report_formats
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


  Endpoint.get('/reports/custom_data')
  .description('Get a list of availiable options for custom reports')
  .permissions([])
  .returns([200], "hash of availiable options") \
  do
    json_response(CustomField.registered_fields)
  end


end
