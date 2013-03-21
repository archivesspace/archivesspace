require_relative 'csv_response'
require_relative 'json_response'

module ReportHelper
  module ResponseHelpers
    def report_response(report, format)
      if format == "csv"
        [200, {"Content-Type" => "text/plain"}, CSVResponse.new(report)]
      else
        # default to json
        [200, {"Content-Type" => "application/json"}, JSONResponse.new(report)]
      end
    end
  end
end