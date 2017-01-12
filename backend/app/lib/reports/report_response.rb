require_relative 'csv_response'
require_relative 'json_response'
require_relative 'xlsx_response'
require_relative 'pdf_response'
require_relative 'html_response'
require 'erb'

# this is a generic wrapper for reports reponses. JasperReports do not 
# need a reponse wrapper and can return reports on formats using the to_FORMAT
# convention. "Classic" AS reports need a wrapper to render the report in a
# specific format.
class ReportResponse
 
  attr_accessor :report
  attr_accessor :base_url

  def initialize(report,  params = {}  )
    @report = report
    @params = params 
  end

  def generate
    if  @report.is_a?(JasperReport) 
      format = @report.format    
      String.from_java_bytes( @report.render(format.to_sym, @params) ) 
    else
      file = File.join( File.dirname(__FILE__), "../../views/reports/report.erb")
      @params[:html_report] ||= proc { ReportErbRenderer.new(@report).render(file) }
    
      format = @report.format

      klass = Object.const_get("#{format.upcase}Response")
      klass.send(:new, @report, @params).generate
    end
  end

end

class ReportErbRenderer
  def initialize(report)
    @report = report
  end

  def render(file)
    ERB.new( File.read(file) ).result(binding)
  end
end
