# prepare an import job run: orchestrates converting the input file's records,
# runs the job and gathers its log output, handling any errors.

[File.expand_path(File.join('..', '..'), File.dirname(__FILE__)),
 *ASUtils.find_local_directories('backend')].each do |prefix|
  Dir.glob(File.join(prefix, "converters", "*.rb")).sort.each do |file|
    require File.absolute_path(file)
  end
end

require_relative '../streaming_import'
require_relative '../ticker'

class BatchImportRunner < JobRunner

  register_for_job_type('import_job', :create_permissions => :import_records,
                                      :cancel_permissions => :cancel_importer_job)


  def run
    ticker = Ticker.new(@job)

    last_error = nil
    batch = nil
    success = false

    filenames = @json.job['filenames'] || []
    import_maint_events = @json.job["import_events"]   == "1" ? true : false
    import_subjects     = @json.job["import_subjects"] == "1" ? true : false
    import_repository   = @json.job["import_repository"] == "1" ? true : false

    # Wrap the import in a transaction if the DB supports MVCC
    begin
      DB.open(DB.supports_mvcc?,
              :retry_on_optimistic_locking_fail => true) do
        created_uris = []
        begin
          @job.job_files.each_with_index do |input_file, i|
            ticker.log(("=" * 50) + "\n#{filenames[i]}\n" + ("=" * 50)) if filenames[i]
            converter = Converter.for(@json.job['import_type'], input_file.full_file_path, {:import_events => import_maint_events, :import_subjects => import_subjects, :import_repository => import_repository})
            begin
              RequestContext.open(:create_enums => true,
                                  :current_username => @job.owner.username,
                                  :repo_id => @job.repo_id) do

                converter.run

                File.open(converter.get_output_path, "r") do |fh|
                  batch = StreamingImport.new(fh, ticker, @import_canceled)
                  batch.process

                  if batch.created_records
                    created_uris.concat(batch.created_records.values)
                  end

                  success = true
                end
              end
            ensure
              converter.remove_files
            end
          end

          # Note: it's important to call `success!` before attempting to store
          # the created URIs here.
          #
          # It turns out that the process of adding a new row to the
          # `job_created_record` table is enough to take a row-level lock on the
          # corresponding job entry in the `job` table (because of the foreign
          # key relationship).  If the import thread locks that row, the
          # watchdog thread ends up deadlocked, and we can't finish the import
          # job.
          #
          # Calling `success!` ensures that the watchdog thread gets shut down.
          # Then it's safe for this thread to do whatever it needs to do to the
          # job tables.
          #
          self.success!
          log_created_uris(created_uris)
        rescue ImportCanceled
          raise Sequel::Rollback
        rescue JSONModel::ValidationException, ImportException, Converter::ConverterMappingError, Sequel::ValidationFailed, ReferenceError => e
          # Note: we deliberately don't catch Sequel::DatabaseError here.  The
          # outer call to DB.open will catch that exception and retry the
          # import for us.
          last_error = e

          # Roll back the transaction (if there is one)
          raise Sequel::Rollback
        end
      end
    rescue
      # If we get to here, last_error will generally not have been set yet.  The
      # conditional set is here to deal with code that does something like this:
      #
      #  DB.open do                 # Start a transaction (1)
      #    BatchImportRunner#run    # Run this import process, which does another DB.open (2)
      #    <run some other updates>
      #  end
      #
      # The intention is to run the import and some related updates in a single
      # transaction, but the result is surprising: if the BatchImportRunner
      # fails for some reason, everything gets rolled back and the only error
      # logged is a Sequel::Rollback.
      #
      # What's happening here is that DB.open (2) actually didn't establish a
      # new transaction (since it was already running in a transaction) and, as
      # a result, Sequel didn't set up the begin/rescue block needed to catch
      # Sequel::Rollback.  So the rollback exception keeps bubbling up until
      # it's caught by the block you're currently reading.  When this happens,
      # last_error contains the real cause of the strife, and Sequel::Rollback
      # should be ignored.

      last_error ||= $!
    end

    if last_error
      ticker.log("\nIMPORT ERROR\n")

      if last_error.respond_to?(:errors)
        ticker.log("#{last_error}") if last_error.errors.empty?
        ticker.log("The following errors were found:\n")

        last_error.errors.each_pair do |k, v|
          ticker.log("\t#{k.to_s}: #{v.join(' -- ')}")
        end

        if last_error.is_a?(Sequel::ValidationFailed)
          ticker.log("\n" )
          ticker.log("%" * 50 )
          ticker.log("\n Full Error Message:\n #{last_error.to_s}\n\n")
        end

        if last_error.respond_to?(:invalid_object) && last_error.invalid_object
          ticker.log("\n\n For #{ last_error.invalid_object.class }: \n #{ last_error.invalid_object.inspect }")
        end

        if ( last_error.respond_to?(:import_context) && last_error.import_context )
          ticker.log("\n\nIn : \n #{ CGI.escapeHTML( last_error.import_context ) } ")
          ticker.log("\n\n")
        end
      else
        ticker.log("Trace:" + last_error.backtrace.inspect)
        ticker.log("Errors: #{last_error.inspect}")
        Log.exception(last_error)
      end

      raise last_error
    end
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
