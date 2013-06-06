require_relative '../lib/streaming_import'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/batch_imports')
    .description("Import a batch of records")
    .params(["batch_import", :body_stream, "The batch of records"],
            ["repo_id", :repo_id])
    .request_context(:create_enums => true)
    .use_transaction(false)
    .permissions([:update_archival_record])
    .returns([200, :created],
             [400, :error],
             [409, :error]) \
  do

    # The first time we're invoked, spool our input into a file.  Since the
    # transaction might get aborted and restarted, the body of this endpoint
    # might get invoked more than once (if the import gets rolled back, for
    # example).  That's fine: we'll reopen and reprocess the temp file.

    if !env['batch_import_file']
      stream = params[:batch_import]
      tempfile = Tempfile.new('import_stream')

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

      # Wrap the import in a transaction if the DB supports MVCC
      DB.open(DB.supports_mvcc?) do
        File.open(env['batch_import_file']) do |stream|
          begin
            batch = StreamingImport.new(stream, job_monitor)

            mapping = batch.process
            job_monitor.results = {:saved => Hash[mapping.map {|logical, real_uri|
                                                    [logical, [real_uri, JSONModel.parse_reference(real_uri)[:id]]]}]}
          rescue JSONModel::ValidationException, ImportException, Sequel::ValidationFailed, Sequel::DatabaseError, ReferenceError => e
            job_monitor.results = {:errors => [e]}

            # Roll back the transaction (if there is one)
            raise Sequel::Rollback
          ensure
            job_monitor.results = {:errors => ["Server error"]} unless job_monitor.results?
            job_monitor.finish!
          end
        end
      end

      File.unlink(env['batch_import_file'])
    end


    [200, {"Content-Type" => "text/plain"}, live_updates]
  end
end
