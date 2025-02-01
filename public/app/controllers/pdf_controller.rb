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

      pdf = FindingAidPDF.new(params[:rid], resource_id, archivesspace, "#{request.protocol}#{request.host_with_port}")
      pdf_file = pdf.generate

      if params.fetch(:token, nil)
        params[:token].gsub!(/[^a-f0-9]/, '')
      end

      respond_to do |format|
        format.all do
          fh = File.open(pdf_file.path)
          pdf_content = fh.read
          fh.close
          pdf_file.unlink

          send_data(pdf_content, :filename => pdf.suggested_filename,
                   :type => "application/pdf", :disposition => 'attachment')
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
