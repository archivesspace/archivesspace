class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/find_by_id/resources')
    .description("Find Resources by their identifiers")
    .params(["repo_id", :repo_id],
            ["identifier", [String], "A 4-part identifier expressed as JSON array (of up to 4 strings)", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    identifiers = Array(params[:identifier]).map {|identifier|
      parsed = ASUtils.json_parse(identifier)

      if parsed.is_a?(Array) && parsed.length > 0 && parsed.length <= 4
        padded = (parsed + ([nil] * 3)).take(4)
        ASUtils.to_json(padded)
      end
    }.compact

    refs = IDLookup.new.find_by_ids(Resource, :identifier => identifiers)
    json_response(resolve_references({'resources' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/archival_objects')
    .description("Find Archival Objects by ref_id or component_id")
    .params(["repo_id", :repo_id],
            ["ref_id", [String], "A set of record Ref IDs", :optional => true],
            ["component_id", [String], "A set of record component IDs", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(ArchivalObject, :ref_id => params[:ref_id], :component_id => params[:component_id])
    json_response(resolve_references({'archival_objects' => refs}, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/find_by_id/digital_object_components')
    .description("Find Digital Object Components by component_id")
    .params(["repo_id", :repo_id],
            ["component_id", [String], "A set of record component IDs", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObjectComponent, :component_id => params[:component_id])
    json_response(resolve_references({'digital_object_components' => refs}, params[:resolve]))
  end

  Endpoint.get('/repositories/:repo_id/find_by_id/digital_objects')
    .description("Find Digital Objects by digital_object_id")
    .params(["repo_id", :repo_id],
            ["digital_object_id", [String], "A set of digital object IDs", :optional => true],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "JSON array of refs"]) \
  do
    refs = IDLookup.new.find_by_ids(DigitalObject, :digital_object_id => params[:digital_object_id])
    json_response(resolve_references({'digital_objects' => refs}, params[:resolve]))
  end

end
