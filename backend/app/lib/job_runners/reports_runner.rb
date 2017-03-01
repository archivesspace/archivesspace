require_relative '../reports/report_response'
require_relative '../reports/report_helper'
require 'json'

class ReportRunner < JobRunner
  
  include JSONModel

  register_for_job_type('report_job')


  def self.reports
   ReportManager.registered_reports
  end


  def run
    super
    @job.write_output("Generating report")
    file = ASUtils.tempfile("report_job_")
    begin 
    
      job_data = @json.job
      
      # we need to massage the json sometimes..
      begin 
        params = ASUtils.json_parse(@json.job_params[1..-2].delete("\\"))
      rescue JSON::ParserError
        params = {}
      end
      params[:format] = job_data["format"] || "pdf"
      params[:repo_id] = @json.repo_id

      report = ReportRunner.reports[job_data['report_type']]                                                                                                                         
      report_model = report[:model]

      output = DB.open do |db|
        ReportResponse.new(report_model.new(params, @job, db)).generate
      end

      if output.respond_to? :string
        file.write(output.string)
      elsif output.respond_to? :each
        output.each do |chunk|
          file.write(chunk)
        end
      else
        file.write(output)
      end
      file.rewind
       
      
      
      @job.write_output("Adding report file.")
      @job.add_file( file )
    
      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e 
    ensure
      file.close
      file.unlink
      @job.write_output("Done.")
   
    end 
  end

end
