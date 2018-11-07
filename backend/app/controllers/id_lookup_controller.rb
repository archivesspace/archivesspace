class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/find_by_id/resources')
    .description("Find Resources by their identifiers")
    .params(["repo_id", :repo_id],
            ["identifier", [String], "A 4-part identifier expressed as a JSON array (of up to 4 strings) comprised of the id_0 to id_3 fields (though empty fields will be handled if not provided)", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(Resource, params)
    json_response(resolve_references({'resources' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/archival_objects')
    .description("Find Archival Objects by ref_id or component_id")
    .params(["repo_id", :repo_id],
            ["ref_id", [String], "An archival object's Ref ID (param may be repeated)", :optional => true],
            ["component_id", [String], "An archival object's component ID (param may be repeated)", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(ArchivalObject, params)
    json_response(resolve_references({'archival_objects' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/digital_object_components')
    .description("Find Digital Object Components by component_id")
    .params(["repo_id", :repo_id],
            ["component_id", [String], "A digital object component's component ID (param may be repeated)", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObjectComponent, params)
    json_response(resolve_references({'digital_object_components' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/digital_objects')
    .description("Find Digital Objects by digital_object_id")
    .params(["repo_id", :repo_id],
            ["digital_object_id", [String], "A digital object's digital object ID (param may be repeated)", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObject, params)
    json_response(resolve_references({'digital_objects' => refs}, params[:resolve]))
  end

end
