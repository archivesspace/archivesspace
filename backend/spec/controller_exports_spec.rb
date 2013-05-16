require 'spec_helper'

describe 'Exports controller' do

  it "lets you export an Agent as EAC, even when it is linked to be records from another repo" do

    accession = create(:json_accession)

    create(:json_event,
           'linked_agents' => [{'ref' => '/agents/software/1', 'role' => 'validator'}],
           'linked_records' => [{'ref' => accession.uri, 'role' => 'source'}])


    get '/archival_contexts/softwares/1.xml'
    last_response.should be_ok
    last_response.body.should match(/<eac-cpf/)
  end


  it "lets you export a person in EAC-CPF" do
    id = create(:json_agent_person).id
    get "/archival_contexts/people/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>person<\/entityType>/)
  end


  it "lets you export a family in EAC-CPF" do
    id = create(:json_agent_family).id
    get "/archival_contexts/families/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>family<\/entityType>/)
  end


  it "lets you export a corporate entity in EAC-CPF" do
    id = create(:json_agent_corporate_entity).id
    get "/archival_contexts/corporate_entities/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>corporateBody<\/entityType>/)
  end


  it "lets you export a software in EAC-CPF" do
    id = create(:json_agent_software).id
    get "/archival_contexts/softwares/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>software<\/entityType>/)
  end


  it "lets you export a resource in EAD" do
    res = create(:json_resource)
    get "/repositories/#{$repo_id}/resource_descriptions/#{res.id}.xml"
    resp = last_response.body
    resp.should match(/<ead/)
    resp.should match(/<eadid>#{res.id_0}/)
  end


  it "lets you export a resource in MARC 21" do
    res = create(:json_resource)
    get "/repositories/#{$repo_id}/resources/marc21/#{res.id}.xml"
    resp = last_response.body
    resp.should match(/<subfield code="c">#{res.id_0}/)
  end


  it "lets you export labels for a resource as tab separated values" do
    id = create(:json_resource).id
    get "/repositories/#{$repo_id}/resource_labels/#{id}.tsv"
    resp = last_response.body
    resp.should match(/Repository Name\t/)
  end


  it "lets you export a digital object in MODS" do
    dig = create(:json_digital_object)
    get "/repositories/#{$repo_id}/digital_objects/mods/#{dig.id}.xml"
    resp = last_response.body
    resp.should match(/<title>#{dig.title}<\/title>/)
  end


  it "lets you export a digital object in METS" do
    dig = create(:json_digital_object)
    get "/repositories/#{$repo_id}/digital_objects/mets/#{dig.id}.xml"
    resp = last_response.body
    resp.should match(/<mods:title>#{dig.title}<\/mods:title>/)
  end


  it "lets you export a digital object in Dublin Core" do
    dig = create(:json_digital_object)
    get "/repositories/#{$repo_id}/digital_objects/dublin_core/#{dig.id}.xml"
    resp = last_response.body
    resp.should match(/<dc:title>#{dig.title}<\/dc:title>/)
  end

end
