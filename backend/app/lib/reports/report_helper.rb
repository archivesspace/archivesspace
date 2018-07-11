require_relative 'report_response'


module ReportHelper

  ALLOWED_REPORT_FORMATS = ["json", "csv", "html", "pdf"]

  def self.allowed_report_formats
    ALLOWED_REPORT_FORMATS
  end


  def self.report_formats
    ["format",
     String,
     "The format to render the report (one of: #{ALLOWED_REPORT_FORMATS.join(", ")})",
     :validation => ["Must be one of #{ALLOWED_REPORT_FORMATS.join(", ")}",
                     ->(v){ ALLOWED_REPORT_FORMATS.include?(v) }]]
  end

end
