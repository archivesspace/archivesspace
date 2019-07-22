require 'java'

class PdfController <  ApplicationController

  skip_before_action :verify_authenticity_token, only: :resource

  PDF_MUTEX = java.util.concurrent.Semaphore.new(AppConfig[:pui_max_concurrent_pdfs])

  def resource
    PDF_MUTEX.acquire
    begin
      repo_id = params.fetch(:rid, nil)
      resource_id = params.fetch(:id, nil)
      token = params.fetch(:token, nil)

      pdf = FindingAidPDF.new(repo_id, resource_id, archivesspace, "#{request.protocol}#{request.host_with_port}")
      pdf_file = pdf.generate

      if token
        token.gsub!(/[^a-f0-9]/, '')
        cookies["pdf_generated_#{token}"] = { value: token, expires: 5.minutes.from_now, http_only: true }
      end

      respond_to do |format|
        filename = pdf.suggested_filename

        format.all do
          fh = File.open(pdf_file.path, "r")
          self.headers["Content-type"] = "application/pdf"
          self.headers["Content-disposition"] = "attachment; filename=\"#{filename}\""
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
    ensure
      PDF_MUTEX.release
    end
  end

end
