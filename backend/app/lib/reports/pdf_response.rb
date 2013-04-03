require "java"
require "flying_saucer"
java_import org.xhtmlrenderer.pdf.ITextRenderer

class PDFResponse

  def initialize(report, html_report, base_url)
    @report = report
    @html_report = html_report
    @base_url = base_url
  end

  def generate
    estimated_pdf_length = @html_report.length
    output = java.io.ByteArrayOutputStream.new(estimated_pdf_length)
    begin
      dom = java_dom(@html_report)
      render_pdf(dom, output)
    ensure
      output.close
    end
  end

  private

  def java_dom(html)
    begin
      builder = javax.xml.parsers.DocumentBuilderFactory.new_instance.new_document_builder
      builder.parse(java.io.ByteArrayInputStream.new(html.to_java_bytes))
    rescue NativeException => e
      puts "Exception generating DOM for PDF: #{e.inspect}"
      java_e = e.cause
      if java_e.is_a?(org.xml.sax.SAXParseException)
        puts "-- java_e: #{java_e.inspect}"
        puts "-- line: #{java_e.line_number}"
        puts "-- html: #{html.inspect}"
      end
      raise e
    end
  end

  def render_pdf(dom, output)
    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new

    renderer.set_document(dom, base_url)
    renderer.layout

    renderer.create_pdf(output)
    String.from_java_bytes(output.to_byte_array)
  end

  def base_url
    java.io.File.new(@base_url).to_uri.to_url.to_string
  end
end