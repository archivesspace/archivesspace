class PdfController <  ApplicationController

  # If true, we'll just generate and return the PDF file on the fly.  False and
  # we'll queue it up and email a link.
  #
  # Really just leaving this here for ease of testing.
  SERVE_DIRECTLY = false

  def resource
    repo_id = params.fetch(:rid, nil)
    resource_id = params.fetch(:id, nil)
    recipient_address = params.fetch(:user_email, nil)

    raise "No email set" unless recipient_address

    if SERVE_DIRECTLY
      pdf = FindingAidPDF.new(repo_id, resource_id, recipient_address, "#{request.protocol}#{request.host_with_port}")
      pdf_file = pdf.generate

      respond_to do |format|
        format.all do
          fh = File.open(pdf_file.path, "r")
          self.headers["Content-type"] = "application/pdf"
          self.response_body = Enumerator.new do |y|
            begin
              while chunk = fh.read(4096)
                y << chunk
              end
            ensure
              fh.close
              pdf_file.unlink
            end
          end
        end
      end

    else
      PDFGeneratorQueue.enqueue(repo_id, resource_id, recipient_address, "#{request.protocol}#{request.host_with_port}")

      respond_to do |format|
        format.all do
          flash[:notice] = I18n.t('pdf_reports.coming_soon')
          redirect_back(fallback_location: '/')
        end
      end
    end
  end

end
