require 'java'

class PdfController < ApplicationController

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
      end

      respond_to do |format|
        # Remove all special characters from filename.
        filename_extension = File.extname(pdf.suggested_filename) # Extract file extension
        filename = pdf.suggested_filename.gsub(filename_extension, '') # Remove file extension
        filename = filename.gsub(/[^a-zA-Z0-9\s]/, '_') # Replace all special characters with underscores
        filename.chop! if filename[-1] == '_' # Remove last underscore
        filename = filename.gsub(/_+/, '_') # Replace underscores multiple with one underscore

        filename = "#{filename}#{filename_extension}"

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
