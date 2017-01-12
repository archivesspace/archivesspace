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

  def transform_text(s)
    # The HTML to PDF library doesn't currently support the "break-word" CSS
    # property that would let us force a linebreak for long strings and URIs.
    # Without that, we end up having our tables chopped off, which makes them
    # not-especially-useful.
    #
    # Newer versions of the library might fix this issue, but it appears that the
    # licence of the newer version is incompatible with the current ArchivesSpace
    # licence.
    #
    # So, we wrap runs of characters in their own span tags to give the renderer
    # a hint on where to place the line breaks.  Pretty terrible, but it works.
    #
    if @report.format === 'pdf'
      escaped = CGI.escapeHTML(s)

      # Exciting regexp time!  We break our string into "tokens", which are either:
      #
      #   - A single whitespace character
      #   - A HTML-escaped character (like '&amp;')
      #   - A run of between 1 and 5 letters
      #
      # Each token is then wrapped in a span, ensuring that we don't go too
      # long without having a spot to break a word if needed.
      #
      escaped.scan(/[\s]|&.*;|[^\s]{1,5}/).map {|token|
        if token.start_with?("&") || token =~ /\A[\s]\Z/
          # Don't mess with &amp; and friends, nor whitespace
          token
        else
          "<span>#{token}</span>"
        end
      }.join("")
    else
      CGI.escapeHTML(s)
    end
  end
end
