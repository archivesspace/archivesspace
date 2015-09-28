require_relative 'report_response'


module ReportHelper

  ALLOWED_REPORT_FORMATS = ["json", "csv", "xlsx", "html", "pdf"]

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



  module ResponseHelpers
    def report_header(report, format) 
      headers = { 
        "csv" => {"Content-Type" => "text/plain; charset=UTF-8", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.csv\""}, 
        "xlsx" => {"Content-Type" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.xlsx\""},
        "html" => {"Content-Type" => "text/html", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.html\""}, 
        "pdf" =>  {"Content-Type" => "application/pdf", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.pdf\""}, 
        "json" => {"Content-Type" => "application/json; charset=UTF-8", "Content-Disposition" => "attachment; filename=\"#{report.class.name}.json\"" }
      }
      headers[format]
    end
    
    def report_response(report, format, report_params = {} )
      report_params[:base_url] ||= request.base_url
      report_params[:html_report] ||= proc {  erb(:'reports/report', :locals => {:report => report}) }    
      begin 
        [200, report_header(report, format) ,  ReportResponse.new(report, format, report_params).generate ] 
      rescue => e
        [404,{"Content-Type" => "application/json; charset=UTF-8"}  ,
          [  {  "error" =>{  report.class.name => [ e.inspect ], 
                "message" => [ e.message ], 
                "backtrace" => [  e.backtrace.join("\n") ] }}.to_json 
          ]
        ]
      end 
    end 
      
  end
end
