class ArchivesSpaceService < Sinatra::Base
  Endpoint.get("/ark*/:naan/:id")
    .description("Redirect to resource identified by ARK Name")
    .params(["id", :id])
    .permissions([])
    .returns([404, "Not found"],
             [302, :redirect]) \
  do
    if ark = ArkName[params[:id]]
      response_hash = find_entity_data(ark)
      json_response(response_hash)
    else
      json_response({"type" => "not_found"})
    end
  end

  def find_entity_data(ark)
    if ark.resource_id
      klass = Resource
      id = ark.resource_id
    elsif ark.archival_object_id
      klass = ArchivalObject
      id = ark.archival_object_id
    end

    rh = if entity = klass.any_repo.filter(:id => id).first
           if entity.external_ark_url
             {"type" => "external", "external_url" => entity.external_ark_url}
           else
             {"type" => klass.to_s,
              "repo_id" => entity[:repo_id],
              "id" => id}
           end
         else
           {"type" => "not_found"}
         end

    return rh
  end
end
