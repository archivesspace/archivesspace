# a really awesome wrapper to just sent a report's HTML response 
# Not needed for JasperReports
#
class HTMLResponse

  def initialize( report, params)
    @report =report
    @params = params
    @html_report = params[:html_report].call 
  end
  
  def generate
    @html_report 
  end

end
