require 'java'

class PdfController < ApplicationController

  PDF_MUTEX = java.util.concurrent.Semaphore.new(AppConfig[:pui_max_concurrent_pdfs])

  def resource
    PDF_MUTEX.acquire
    begin
      # If coming from an archival object view, get the resource ID from the archival object
      resource_id = if request.referrer&.include?('archival_objects')
                      ao = archivesspace.get_record("/repositories/#{params[:rid]}/archival_objects/#{params[:id]}")
                      # Get resource ID from the archival object's json
                      ao.json['resource']['ref']&.split('/')&.last
                    else
                      params[:id]
                    end

      raise RecordNotFound.new("No resource ID found") unless resource_id

      pdf = FindingAidPDF.new(params[:rid], resource_id, archivesspace, "#{request.protocol}#{request.host_with_port}")
      pdf_file = pdf.generate

      if params.fetch(:token, nil)
        params[:token].gsub!(/[^a-f0-9]/, '')
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
          self.headers["Content-Type"] = "application/pdf"
          self.headers["Content-Length"] = File.size(pdf_file.path).to_s
          self.headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"; filename*=UTF-8''#{ERB::Util.url_encode(filename)}"
          self.headers["X-Content-Type-Options"] = "nosniff"
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
  rescue => e
    Rails.logger.error "PDF generation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

end
