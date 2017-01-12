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

  Endpoint.get('/reports/run_report_please')
  .description('For dev only')
  .params(["report", String, "Report to run"])
  .permissions([])
  .returns([200, "HTML report"]) \
  do
    # NOTE: Terrible idea for security
    report_model = Kernel.const_get(params[:report])

    DB.open do |db|
      p ReportResponse.new(report_model.new({:format => 'html'}, :job, db)).generate
    end
  end

end
