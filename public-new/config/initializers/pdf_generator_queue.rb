ActionDispatch::Callbacks.to_prepare do
  Rails.logger.info("Starting PDF generation queue")
  PDFGeneratorQueue.start
end
