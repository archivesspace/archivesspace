require_relative '../lib/streaming_import'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/batch_imports')
    .description("Import a batch of records")
    .params(["batch_import", :body_stream, "The batch of records"],
            ["repo_id", :repo_id],
            ["use_transaction", String,
             ("Specifies whether to perform the import within a database transaction. " +
              "Default is database-dependent: MySQL uses a transaction, but the demo DB doesn't. " +
              "You can force the demo DB to use a transaction by setting this parameter to 'true', but " +
              "note that the system may become unresponsive while the import is running."),
             :validation => ["Must be one of 'true', 'false' or 'auto'",
                             ->(v){ ['true', 'false', 'auto'].include?(v) }],
             :default => 'auto'])
    .request_context(:create_enums => true)
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

    File.unlink(env['batch_import_file'])

    live_updates = ProgressTicker.new(:frequency_seconds => 1) do |job_monitor|

      begin
        batch = StreamingImport.new(stream, job_monitor)
        
        mapping = batch.process
        job_monitor.results = {:saved => Hash[mapping.map {|logical, real_uri|
                         [logical, [real_uri, JSONModel.parse_reference(real_uri)[:id]]]}]}
      rescue JSONModel::ValidationException => e
        job_monitor.results = {:errors => [e]}                   
      
      rescue ImportException => e
        job_monitor.results = {:errors => [e]}
      rescue Sequel::ValidationFailed => e
        job_monitor.results = {:errors => [e]}
      ensure
        job_monitor.results = {:errors => ["Server error"]} unless job_monitor.results?
        job_monitor.finish!
      end
    end


    [200, {"Content-Type" => "text/plain"}, live_updates]
  end
end
