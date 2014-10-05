require_relative 'csv_response'
require_relative 'json_response'
require_relative 'xlsx_response'
require_relative 'pdf_response'
require_relative 'html_response'

# this is a generic wrapper for reports reponses. JasperReports do not 
# need a reponse wrapper and can return reports on formats using the to_FORMAT
# convention. "Classic" AS reports need a wrapper to render the report in a
# specific format.
class ReportResponse
 
  attr_accessor :report
  attr_accessor :format
  attr_accessor :base_url

  def initialize(report, format, params = {}  )
    @report = report
    @format = format 
    @params = params 
  end

  def generate
    if  @report.is_a?(JasperReport) 
      String.from_java_bytes( @report.render(@format.to_sym) ) 
    else
      klass = Object.const_get("#{@format.upcase}Response")
      klass.send(:new, @report, @params).generate
    end
  end

end
