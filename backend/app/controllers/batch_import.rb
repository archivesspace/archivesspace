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

    posted_batch = params[:batch_import]

    progressive_response = ProgressTicker.new(:frequency_seconds => 2) do |progress_ticker|

      batch = StreamingImport.new(posted_batch, progress_ticker)

      begin
        mapping = batch.process
        response_hash = {:saved => Hash[mapping.map {|logical, real_uri|
                         [logical, [real_uri, JSONModel.parse_reference(real_uri)[:id]]]}]}
      rescue ImportException => e
        Log.error(e)
        response_hash = {:saved => [], :errors => [e.to_s]}
      ensure
        response_hash = {:saved => [], :errors => ["Server error"]} unless response_hash
        progress_ticker.finished(response_hash)
      end
    end


    [200, {"Content-Type" => "text/plain"}, progressive_response]
                      

  end

end
