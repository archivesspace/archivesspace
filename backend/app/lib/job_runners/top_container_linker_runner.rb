
class TopContainerLinkerRunner < JobRunner

  register_for_job_type('top_container_linker_job')

  def run
     
#    begin
#      job_data = @json.job
#          
#      terminal_error = nil
#         
#      DB.open(DB.supports_mvcc?,
#              :retry_on_optimistic_locking_fail => true) do
#
#        begin
#          
#          RequestContext.open(:current_username => @job.owner.username,
#            :repo_id => @job.repo_id) do
#
#
#              File.open(converter.get_output_path, "r") do |fh|
#                  batch = StreamingImport.new(fh, ticker, @import_canceled)
#                  batch.process
#
#                  if batch.created_records
#                    created_uris.concat(batch.created_records.values)
#                  end
#
#                  success = true
#                end
#              end
#            ensure
#              converter.remove_files
#            end
#
#
#          # Note: it's important to call `success!` before attempting to store
#          # the created URIs here.
#          #
#          # It turns out that the process of adding a new row to the
#          # `job_created_record` table is enough to take a row-level lock on the
#          # corresponding job entry in the `job` table (because of the foreign
#          # key relationship).  If the import thread locks that row, the
#          # watchdog thread ends up deadlocked, and we can't finish the import
#          # job.
#          #
#          # Calling `success!` ensures that the watchdog thread gets shut down.
#          # Then it's safe for this thread to do whatever it needs to do to the
#          # job tables.
#          #
#          self.success!
#          log_created_uris(created_uris)
#        rescue ImportCanceled
#          raise Sequel::Rollback
#        rescue JSONModel::ValidationException, ImportException, Converter::ConverterMappingError, Sequel::ValidationFailed, ReferenceError => e
#          # Note: we deliberately don't catch Sequel::DatabaseError here.  The
#          # outer call to DB.open will catch that exception and retry the
#          # import for us.
#          last_error = e
#
#          # Roll back the transaction (if there is one)
#          raise Sequel::Rollback
#        end
#      end
#    rescue
#      last_error = $!
#    end
#
#    if last_error
#     
#      ticker.log("\n\n" ) 
#      ticker.log( "!" * 50 ) 
#      ticker.log( "IMPORT ERROR" ) 
#      ticker.log( "!" * 50 ) 
#      ticker.log("\n\n" ) 
#      
#      if  last_error.respond_to?(:errors)
#     
#        ticker.log("#{last_error}") if last_error.errors.empty? # just spit it out if there's not explicit errors
#        
#        ticker.log("The following errors were found:\n") 
#        
#        last_error.errors.each_pair { |k,v| ticker.log("\t#{k.to_s} : #{v.join(' -- ')}" ) }
#        
#        if last_error.is_a?(Sequel::ValidationFailed) 
#          ticker.log("\n" ) 
#          ticker.log("%" * 50 ) 
#          ticker.log("\n Full Error Message:\n #{last_error.to_s}\n\n") 
#        end 
#        
#        if ( last_error.respond_to?(:invalid_object) && last_error.invalid_object ) 
#          ticker.log("\n\n For #{ last_error.invalid_object.class }: \n #{ last_error.invalid_object.inspect  }")  
#        end 
#        
#        if ( last_error.respond_to?(:import_context) && last_error.import_context )
#          ticker.log("\n\nIn : \n #{ CGI.escapeHTML( last_error.import_context ) } ")
#          ticker.log("\n\n") 
#        end 
#      else
#        ticker.log("Error: #{CGI.escapeHTML(  last_error.inspect )}")
#        Log.exception(last_error)
#      end
#      ticker.log("!" * 50 ) 
#      raise last_error
#    end
  end


  private

  def log_created_uris(uris)
    if !uris.empty?
      DB.open do |db|
        @job.record_created_uris(uris)
      end
    end
  end

end
