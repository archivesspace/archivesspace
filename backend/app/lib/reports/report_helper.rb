require_relative 'csv_response'
require_relative 'json_response'
require_relative 'xlsx_response'

module ReportHelper
  module ResponseHelpers
    def report_response(report, format)
      # if download - "Content-Disposition" => "attachment; filename=\"#{report.class.name}_#{Time.now.iso8601}.csv\""

      if format == "csv"
        [200, {"Content-Type" => "text/plain"}, CSVResponse.new(report)]
      elsif format == "xlsx"
        [200, {"Content-Type" => "text/plain", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.xlsx\""}, XLSXResponse.new(report).to_stream]
      else
        # default to json
        [200, {"Content-Type" => "application/json"}, JSONResponse.new(report)]
      end
    end
  end
end