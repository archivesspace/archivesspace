class ArchivesSpaceService < Sinatra::Base

  include ExportHelpers

  Endpoint.get('/repositories/:repo_id/digital_objects/dublin_core/:id.xml')
    .description("Get a Dublin Core representation of a Digital Object ")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    dc = generate_dc(params[:id])

    xml_response(dc)
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/dublin_core/:id.:fmt/metadata')
    .description("Get metadata for a Dublin Core export")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({"filename" => safe_filename(DigitalObject[params[:id]].digital_object_id, "_dc.xml" ),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/mets/:id.xml')
    .description("Get a METS representation of a Digital Object ")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["dmd", String, "DMD Scheme to use", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    mets = generate_mets(params[:id], params[:dmd])

    xml_response(mets)
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/mets/:id.:fmt/metadata')
    .description("Get metadata for a METS export")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({"filename" =>
                    safe_filename(DigitalObject[params[:id]].digital_object_id, "_mets.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/mods/:id.xml')
    .description("Get a MODS representation of a Digital Object ")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    mods = generate_mods(params[:id])

    xml_response(mods)
  end


  Endpoint.get('/repositories/:repo_id/digital_objects/mods/:id.:fmt/metadata')
    .description("Get metadata for a MODS export")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({"filename" =>
                    safe_filename(DigitalObject[params[:id]].digital_object_id, "_mods.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/resources/marc21/:id.xml')
    .description("Get a MARC 21 representation of a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["include_unpublished_marc", BooleanParam, "Include unpublished notes", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do

    marc = generate_marc(params[:id], params[:include_unpublished_marc])

    xml_response(marc)
  end


  Endpoint.get('/repositories/:repo_id/resources/marc21/:id.:fmt/metadata')
    .description("Get metadata for a MARC21 export")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["include_unpublished_marc", BooleanParam, "Include unpublished notes", :optional => true])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({"filename" =>
                    safe_filename(Resource.id_to_identifier(params[:id]), "_marc21.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.xml')
    .description("Get an EAD representation of a Resource")
    .params(["id", :id],
            ["include_unpublished", BooleanParam,
             "Include unpublished records", :optional => true],
            ["include_daos", BooleanParam,
             "Include digital objects in dao tags", :optional => true],
            ["numbered_cs", BooleanParam,
             "Use numbered <c> tags in ead", :optional => true],
            ["print_pdf", BooleanParam,
             "Print EAD to pdf", :optional => true],
            ["repo_id", :repo_id],
            ["ead3", BooleanParam,
             "Export using EAD3 schema", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    redirect to("/repositories/#{params[:repo_id]}/resource_descriptions/#{params[:id]}.pdf?#{ params.map { |k,v| "#{k}=#{v}" }.join("&") }") if params[:print_pdf]
    ead_stream = generate_ead(params[:id],
                              (params[:include_unpublished] || false),
                              (params[:include_daos] || false),
                              (params[:numbered_cs] || false),
                              (params[:ead3] || false))

    stream_response(ead_stream)
  end

  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.pdf')
    .description("Get an EAD representation of a Resource")
    .params(["id", :id],
            ["include_unpublished", BooleanParam,
             "Include unpublished records", :optional => true],
            ["include_daos", BooleanParam,
             "Include digital objects in dao tags", :optional => true],
            ["numbered_cs", BooleanParam,
             "Use numbered <c> tags in ead", :optional => true],
            ["print_pdf", BooleanParam,
             "Print EAD to pdf", :optional => true],
            ["repo_id", :repo_id],
            ["ead3", BooleanParam,
             "Export using EAD3 schema", :optional => true])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    ead_stream = generate_ead(params[:id],
                              (params[:include_unpublished] || false),
                              (params[:include_daos] || false),
                              (params[:numbered_cs] || false),
                              (params[:ead3] || false))

    repo = resolve_references(Repository.get_or_die(params[:repo_id]),
                              params[:resolve])

    if repo['image_url']
      image_for_pdf = repo['image_url']
    else
      image_for_pdf = nil
    end

    pdf = generate_pdf_from_ead(ead_stream, image_for_pdf)
    pdf_response(pdf)
  end


  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.:fmt/metadata')
    .description("Get export metadata for a Resource Description")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["fmt", String, "Format of the request",
                      :optional => true])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do



      json_response({"filename" => safe_filename(Resource.id_to_identifier(params[:id]), "_ead.#{params[:fmt]}" ),
                   "mimetype" => "application/#{params[:fmt]}"})
  end


  Endpoint.get('/repositories/:repo_id/resource_labels/:id.tsv')
    .description("Get a tsv list of printable labels for a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    tsv = generate_labels(params[:id])

    tsv_response(tsv)
  end


  Endpoint.get('/repositories/:repo_id/resource_labels/:id.:fmt/metadata')
    .description("Get export metadata for Resource labels")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "The export metadata"]) \
  do
    json_response({"filename" =>
                    safe_filename(Resource.id_to_identifier(params[:id]), "_labels.tsv"),
                    "mimetype" => 'text/tab-separated-values'})
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/people/:id.xml')
    .description("Get an EAC-CPF representation of an Agent")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_person')

    xml_response(eac)
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/people/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a person")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentPerson.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join("_")
    json_response({"filename" => safe_filename(fn, "_eac.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/corporate_entities/:id.xml')
    .description("Get an EAC-CPF representation of a Corporate Entity")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_corporate_entity')

    xml_response(eac)
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/corporate_entities/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a corporate entity")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentCorporateEntity.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['primary_name']].compact.join("_")
    json_response({"filename" => safe_filename(fn, "_eac.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/families/:id.xml')
    .description("Get an EAC-CPF representation of a Family")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_family')

    xml_response(eac)
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/families/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a family")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentFamily.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['family_name']].compact.join("_")
    json_response({"filename" => safe_filename(fn, "_eac.xml"),
                   "mimetype" => "application/xml"})
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/softwares/:id.xml')
    .description("Get an EAC-CPF representation of a Software agent")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_software')

    xml_response(eac)
  end


  Endpoint.get('/repositories/:repo_id/archival_contexts/softwares/:id.:fmt/metadata')
    .description("Get metadata for an EAC-CPF export of a software")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, "The export metadata"]) \
  do
    agent = AgentSoftware.to_jsonmodel(params[:id])
    aname = agent['display_name']
    fn = [aname['authority_id'], aname['software_name']].compact.join("_")
    json_response({"filename" => safe_filename(fn, "_eac.xml"),
                   "mimetype" => "application/xml"})
  end

end
