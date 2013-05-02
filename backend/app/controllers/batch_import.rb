require_relative '../lib/streaming_import'

class ArchivesSpaceService < Sinatra::Base

    #.permissions([:update_archival_record])
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
    .permissions([])
    .returns([200, :created],
             [400, :error],
             [409, :error]) \
  do
    StreamingImport.new(params[:batch_import]).process
  end

end
