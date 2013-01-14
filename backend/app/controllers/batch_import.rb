class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/batch_imports')
    .description("Import a batch of records")
    .params(["batch_import", JSONModel(:batch_import), "The batch of records", :body => true],
            ["repo_id", :repo_id])
    .permissions([:update_repository])
    .returns([200, :created],
             [400, :error],
             [409, :error]) \
  do
    handle_import
  end
  
end
