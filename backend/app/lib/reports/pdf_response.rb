require "java"

#java_import org.xhtmlrenderer.pdf.ITextRenderer

class PDFResponse

  # Provide an `each` method that delivers a file's contents in sensible chunks
  # and then deletes it when all has been read.
  class TempFileStream
    def initialize(path)
      @path = path
      @fh = File.open(path, 'rb')
    end

    def each
      while true
        chunk = @fh.read(4096)

        if chunk
          yield chunk
        else
          break
          @fh.close
          File.unlink(@path)
        end
      end
    end
  end

  def initialize(report, params )
    @report = report
    @html_report = params[:html_report].call
    @base_url = params[:base_url] || "/"
  end

  CONTROL_CHARS = (0...32).map(&:chr)
  VALID_CONTROL_CHARS = [0x9, 0xA, 0xD].map(&:chr)

  def clean_invalid_xml_chars(s)
    s.gsub!(/[#{CONTROL_CHARS.join("")}]/) do |ch|
      if VALID_CONTROL_CHARS.include?(ch)
        ch
      else
        ""
      end
    end
  end

  def generate
    # PDFs can be large, so return a file handle instead of loading everything into memory
    output_pdf_file = java.io.File.createTempFile("pdf_response", "pdf")
    output_stream = java.io.FileOutputStream.new(output_pdf_file)

    html_file = ASUtils.tempfile("pdf_response_html")
    html_file.write(clean_invalid_xml_chars(@html_report))
    html_file.close

    # No longer needed - can be GC'd
    @html_report = nil

    begin
      render_pdf(html_file.path, output_stream)
    ensure
      html_file.unlink
      output_stream.close
    end

    TempFileStream.new(output_pdf_file.path)
  end

  private

  def render_pdf(html_file_path, output_stream)
    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new

    renderer.set_document(java.io.File.new(html_file_path))
    renderer.layout

    renderer.create_pdf(output_stream)
  end

  def base_url
    java.io.File.new(@base_url).to_uri.to_url.to_string
  end
end
