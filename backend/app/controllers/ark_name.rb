class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/ark_name')
    .description("Get the ARK name object for a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, "(:ark_name)"]) \
  do
    json_response(Resource.to_jsonmodel(params[:id])["ark_name"])
  end

  Endpoint.post('/repositories/:repo_id/resources/:id/ark_name')
    .description("Update the ARK name for a Resource")
    .params(["id", :id],
            ["ark_name", JSONModel(:ark_name), "The updated ark_name", :body => true],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, :updated],
             [400, :error]) \
  do
    ArkName.update_for_record(Resource.get_or_die(params[:id]), params[:ark_name])
    json_response(:status => "Updated")
  end

  Endpoint.get('/repositories/:repo_id/archival_objects/:id/ark_name')
    .description("Get the ARK name object for an ArchivalObject")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, "(:ark_name)"]) \
  do
    json_response(ArchivalObject.to_jsonmodel(params[:id])["ark_name"])
  end

  Endpoint.post('/repositories/:repo_id/archival_objects/:id/ark_name')
    .description("Update the ARK name for an ArchivalObject")
    .params(["id", :id],
            ["ark_name", JSONModel(:ark_name), "The updated ark_name", :body => true],
            ["repo_id", :repo_id])
    .permissions([:administer_system])
    .returns([200, :updated],
             [400, :error]) \
  do
    ArkName.update_for_record(ArchivalObject.get_or_die(params[:id]), params[:ark_name])
    json_response(:status => "Updated")
  end

end
