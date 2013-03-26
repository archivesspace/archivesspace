require_relative 'csv_response'
require_relative 'json_response'
require_relative 'xlsx_response'
require_relative 'pdf_response'

module ReportHelper
  module ResponseHelpers
    def report_response(report, format)
      @base_url = request.base_url
      # if download - "Content-Disposition" => "attachment; filename=\"#{report.class.name}_#{Time.now.iso8601}.csv\""

      if format == "csv"
        [200, {"Content-Type" => "text/plain"}, CSVResponse.new(report)]
      elsif format == "xlsx"
        [200, {"Content-Type" => "text/plain", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.xlsx\""}, XLSXResponse.new(report).to_stream]
      elsif format == "html"
        [200, {"Content-Type" => "text/html"}, erb(:'reports/report', :locals => {:report => report})]
      elsif format == "pdf"
        [
          200,
          {"Content-Type" => "application/pdf", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.pdf\""},
          PDFResponse.new(report, erb(:'reports/report', :locals => {:report => report}),  @base_url).generate
        ]
        #stream do |out|
        #  PDFResponse.new(report, erb(:'reports/report', :locals => {:report => report})).to_stream(out)
        #end

      else
        # default to json
        [200, {"Content-Type" => "application/json"}, JSONResponse.new(report)]
      end
    end
  end
end