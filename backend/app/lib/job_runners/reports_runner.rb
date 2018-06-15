require_relative '../reports/report_generator'
require 'json'

class ReportRunner < JobRunner

  include JSONModel

  register_for_job_type('report_job')


  def self.reports
    ReportManager.registered_reports
  end


  def run
    @job.write_output('Generating report')
    file = ASUtils.tempfile('report_job_')
    begin

      job_data = @json.job

      # we need to massage the json sometimes..
      begin
        params = ASUtils.json_parse(@json.job_params[1..-2].delete('\\'))
      rescue JSON::ParserError
        params = {}
      end
      params[:format] = job_data['format'] || 'pdf'
      params[:repo_id] = @json.repo_id

      report_model = ReportRunner.reports[job_data['report_type']][:model]

      report = DB.open do |db|
        report_model.new(params, @job, db)
      end

      file = ASUtils.tempfile('report_job_')
      ReportGenerator.new(report).generate(file)

      file.rewind
      @job.write_output('Adding report file.')

      @job.add_file(file)

      self.success!
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    ensure
      file.close
      file.unlink
      @job.write_output('Done.')

    end
  end

end
