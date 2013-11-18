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


  Endpoint.get('/repositories/:repo_id/digital_objects/mets/:id.xml')
    .description("Get a METS representation of a Digital Object ")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:digital_object)"]) \
  do
    mets = generate_mets(params[:id])

    xml_response(mets)
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

  Endpoint.get('/repositories/:repo_id/resources/marc21/:id.xml')
    .description("Get a MARC 21 representation of a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    marc = generate_marc(params[:id])

    xml_response(marc)
  end


  Endpoint.get('/repositories/:repo_id/resource_descriptions/:id.xml')
    .description("Get an EAD representation of a Resource")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    resp = generate_ead(params[:id])

    stream_response(resp[:stream], resp[:filename])
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

  Endpoint.get('/archival_contexts/people/:id.xml')
    .description("Get an EAC-CPF representation of an Agent")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_person')

    xml_response(eac)
  end

  Endpoint.get('/archival_contexts/corporate_entities/:id.xml')
    .description("Get an EAC-CPF representation of a Corporate Entity")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_corporate_entity')

    xml_response(eac)
  end

  Endpoint.get('/archival_contexts/families/:id.xml')
    .description("Get an EAC-CPF representation of a Family")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_family')

    xml_response(eac)
  end

  Endpoint.get('/archival_contexts/softwares/:id.xml')
    .description("Get an EAC-CPF representation of a Software agent")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:id], 'agent_software')

    xml_response(eac)
  end
end
