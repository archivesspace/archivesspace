class ArchivesSpaceService < Sinatra::Base
  
  include ExportHelpers

  Endpoint.get('/repositories/:repo_id/resource_descriptions/:resource_id.xml')
    .description("Get an EAD representation of a Resource")
    .params(["resource_id", Integer, "The ID of the resource to retrieve"],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:resource)"]) \
  do
    ead = generate_ead(params[:resource_id], :resource, params[:repo_id])
    
    xml_response(ead)    
  end
  
  Endpoint.get('/archival_contexts/people/:agent_id.xml')
    .description("Get an EAC-CPF representation of an Agent")
    .params(["agent_id", Integer, "The ID of the Agent to retrieve"])
    .nopermissionsyet
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:agent_id], 'agent_person')
    
    xml_response(eac)
  end
  
  Endpoint.get('/archival_contexts/corporate_entities/:agent_id.xml')
    .description("Get an EAC-CPF representation of a Corporate Entity")
    .params(["agent_id", Integer, "The ID of the Agent to retrieve"])
    .nopermissionsyet
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:agent_id], 'agent_corporate_entity')
    
    xml_response(eac)
  end
  
  Endpoint.get('/archival_contexts/families/:agent_id.xml')
    .description("Get an EAC-CPF representation of a Family")
    .params(["agent_id", Integer, "The ID of the Agent to retrieve"])
    .nopermissionsyet
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:agent_id], 'agent_family')
    
    xml_response(eac)
  end
  
  Endpoint.get('/archival_contexts/softwares/:agent_id.xml')
    .description("Get an EAC-CPF representation of a Software agent")
    .params(["agent_id", Integer, "The ID of the Agent to retrieve"])
    .nopermissionsyet
    .returns([200, "(:agent)"]) \
  do
    eac = generate_eac(params[:agent_id], 'agent_software')
    
    xml_response(eac)
  end
  
  
end
