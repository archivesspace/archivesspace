require_relative "../../controllers/lib/bulk_import/top_container_linker"

class TopContainerLinkerRunner < JobRunner

  register_for_job_type('top_container_linker_job')

  def run
     
    begin
      job_data = @json.job
     
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do

        begin
          RequestContext.open(:current_username => @job.owner.username,
            :repo_id => @job.repo_id) do
            if @job.job_files.empty?
              #TODO Throw an error
            end
            input_file = @job.job_files[0].full_file_path
            
            current_user = User.find(:username => @job.owner.username)
            @job.write_output("Creating new top container linker...")
            @job.write_output("Repository: " + @job.repo_id.to_s)
            tcl = TopContainerLinker.new(input_file, @json.job["content_type"], current_user,
              {:rid => @json.job['resource_id'], :repo_id => @job.repo_id})
            
            begin 
              report = tcl.run
              write_out_errors(report)
              
              self.success!
              
            rescue Exception => e
              report = tcl.report
              write_out_errors(report)
              @job.write_output(e.message)
              @job.write_output(e.backtrace)
              raise Sequel::Rollback
            end
         end
         end
       end
    end
  end
  
  private
  def write_out_errors(report)
    modified_uris = []
    report.rows.each do |row|
      if !row.archival_object_id.nil?
        modified_uris << row.archival_object_id
      end
      #Report out the collected data:
      if !row.errors.empty?
        row.errors.each do |error|
          @job.write_output(error)
        end
      end
      if !row.info.empty?
        row.info.each do |info|
          @job.write_output(info)
        end
      end
    end
    if modified_uris.empty?
      @job.write_output("No records modified.")
    else
      @job.write_output("Logging modified records.")
    end
    @job.record_created_uris(modified_uris.uniq)
  end

end
