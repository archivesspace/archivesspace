class ArchivesSpaceService < Sinatra::Base

  include ComponentTransfer::ResponseHelpers

  Endpoint.post('/repositories/:repo_id/component_transfers')
    .description("Transfer components from one resource to another")
    .params(["target_resource", String, "The URI of the resource to transfer into"],
            ["component", String, "The URI of the archival object to transfer"],
            ["repo_id", :repo_id])
    .permissions([:update_resource_record])
    .returns([200, :created],
             [400, :error],
             [409, :error]) \
  do
    component_transfer_response(params[:target_resource], params[:component])
  end

end
