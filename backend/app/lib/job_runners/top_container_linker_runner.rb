require_relative "../../controllers/lib/bulk_import/top_container_linker"

class TopContainerLinkerRunner < JobRunner

  register_for_job_type('top_container_linker_job')

  def run
     
    begin
      job_data = @json.job
     
          
      terminal_error = nil
         
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
            tcl = TopContainerLinker.new(input_file, @json.job["content_type"], 
              {:rid => @json.job['resource_id'], :repo_id => @job.repo_id}, current_user)
            
            begin 
              tcl.run
              report = tcl.report
              modified_uris = []
              report.rows.each do |row|
                modified_uris << row.archival_object_id
                #Report out the collected data:
                if !row.errors.empty?
                  @job.write_output("Errors discovered during linker processing:")
                  row.errors.each do |error|
                    @job.write_output(error)
                  end
                end
                if !row.info.empty?
                  @job.write_output("\nData from linker processing:")
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
              self.success!
              @job.record_created_uris(modified_uris.uniq)
            rescue Exception => e
              report = tcl.report
              @job.write_output(e.message)
              @job.write_output(e.backtrace)
              raise e
            end
         end
         end
       end
    end
end

end
