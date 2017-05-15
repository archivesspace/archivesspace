require 'java'

class PDFGeneratorQueue

  Task = Struct.new(:repo_id, :resource_id, :recipient_address, :base_url)

  def self.start
    @started = true
    @queue = java.util.concurrent.LinkedBlockingQueue.new

    @threads = AppConfig[:pui_max_concurrent_pdfs].times.map do |_|
      Thread.new do
        process_pdfs
      end
    end
  end

  def self.enqueue(repo_id, resource_id, recipient_address, base_url)
    raise "PDF queue is not started" unless @started

    @queue.add(Task.new(repo_id, resource_id, recipient_address, base_url))
  end

  private

  def self.process_pdfs
    loop do
      job = @queue.take

      begin
        Rails.logger.info("Generating PDF #{job.inspect}.  Number of waiting jobs: #{@queue.size}.")

        pdf = FindingAidPDF.new(job.repo_id, job.resource_id, ArchivesSpaceClient.new, job.base_url)
        pdf_file = pdf.generate

        RequestMailer.email_pdf_finding_aid(job.recipient_address, pdf.repo_code, pdf.short_title, pdf.suggested_filename, pdf_file.path).deliver!
      rescue
        Rails.logger.error("PDF generation failed for job: #{job}: #{$!}")
        Rails.logger.error($@.join("\n"))
      end
    end
  end

end
