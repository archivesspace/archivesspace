require_relative '../lib/streaming_import'


class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/batch_imports')
    .description("Import a batch of records")
    .params(["batch_import", :body_stream, "The batch of records"],
            ["repo_id", :repo_id],
            ["migration", String, "Param to indicate we are using a migrator", :optional => true ],
            ["skip_results", BooleanParam, "If true, don't return the list of created record URIs",
             :optional => true ])
    .request_context(:create_enums => true)
    .use_transaction(false)
    .permissions([:import_records])
    .returns([200, :created],
             [400, :error],
             [409, :error]) \
  do

    # some migrators (like Archivists Toolkit) use the batch_import endpoint.
    # however, we can disable some checks, since AT has managed the data in a particular way, so
    # things like ordering should not need to be checked.
    migration = params[:migration] ? true : false

    # The first time we're invoked, spool our input into a file.  Since the
    # transaction might get aborted and restarted, the body of this endpoint
    # might get invoked more than once (if the import gets rolled back, for
    # example).  That's fine: we'll reopen and reprocess the temp file.

    if !env['batch_import_file']
      stream = params[:batch_import]
      tempfile = ASUtils.tempfile('import_stream')

      begin
        while !(buf = stream.read(4096)).nil?
          tempfile.write(buf)
        end
      ensure
        tempfile.close
      end

      env['batch_import_file'] = tempfile
    end

    live_updates = ProgressTicker.new(:frequency_seconds => 1) do |job_monitor|
      last_error = nil
      batch = nil
      success = false

      # Wrap the import in a transaction if the DB supports MVCC
      begin
        DB.open(DB.supports_mvcc?,
                :retry_on_optimistic_locking_fail => true,
                :isolation_level => :committed) do
          last_error = nil

          File.open(env['batch_import_file']) do |stream|
            begin
              batch = StreamingImport.new(stream, job_monitor, false,  migration )
              batch.process
              success = true
            rescue JSONModel::ValidationException, ImportException, Sequel::ValidationFailed, ReferenceError => e
              # Note: we deliberately don't catch Sequel::DatabaseError here.  The
              # outer call to DB.open will catch that exception and retry the
              # import for us.
              last_error = e

              # Roll back the transaction (if there is one)
              raise Sequel::Rollback, last_error
            end
          end
        end
      rescue
        last_error = $!
      ensure
        # If we were running in a transaction, the whole batch will have been
        # rolled back.
        batch = nil if !success && DB.supports_mvcc?
      end


      results = {:saved => []}

      if !params[:skip_results] && batch && batch.created_records
        results[:saved] = Hash[batch.created_records.map {|logical, real_uri|
                                 [logical, [real_uri, JSONModel.parse_reference(real_uri)[:id]]]}]
      end

      if last_error
        Log.exception(last_error)
        results[:errors] = ["Server error: #{last_error}"]
      end

      job_monitor.results = results
      job_monitor.finish!
      File.unlink(env['batch_import_file'])
    end


    [200, {"Content-Type" => "text/plain"}, live_updates]
  end
end
