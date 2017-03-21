require 'spec_helper'

describe 'Exports controller' do

  it "lets you export an Agent as EAC, even when it is linked to records from another repo" do

    accession = create(:json_accession)

    create(:json_event,
           'linked_agents' => [{'ref' => '/agents/software/1', 'role' => 'validator'}],
           'linked_records' => [{'ref' => accession.uri, 'role' => 'source'}])


    get "/repositories/#{$repo_id}/archival_contexts/softwares/1.xml"
    last_response.should be_ok
    last_response.body.should match(/<eac-cpf/)
  end


  it "lets you export a person in EAC-CPF" do
    id = create(:json_agent_person).id
    get "/repositories/#{$repo_id}/archival_contexts/people/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>person<\/entityType>/)
  end


  it "lets you export a family in EAC-CPF" do
    id = create(:json_agent_family).id
    get "/repositories/#{$repo_id}/archival_contexts/families/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>family<\/entityType>/)
  end


  it "lets you export a corporate entity in EAC-CPF" do
    id = create(:json_agent_corporate_entity).id
    get "/repositories/#{$repo_id}/archival_contexts/corporate_entities/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>corporateBody<\/entityType>/)
  end


  it "lets you export a software in EAC-CPF" do
    id = create(:json_agent_software).id
    get "/repositories/#{$repo_id}/archival_contexts/softwares/#{id}.xml"
    resp = last_response.body
    resp.should match(/<eac-cpf/)
    resp.should match(/<control>/)
    resp.should match(/<entityType>software<\/entityType>/)
  end


  it "lets you export a resource in EAD" do
    res = create(:json_resource, :publish => true)
    get "/repositories/#{$repo_id}/resource_descriptions/#{res.id}.xml"
    resp = last_response.body
    resp.should match(/<ead/)
  end


  it "excludes unpublished records in EAD exports by default" do

    resource = create(:json_resource)
    id = resource.id

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = create(:json_archival_object, {:title => "archival object: #{name}",
                                          :resource => {:ref => resource.uri}})
      if not aos.empty?
        ao.parent = {:ref => aos.last.uri}
        ao.publish = false
      end

      ao.save
      aos << ao
    end

    get "/repositories/#{$repo_id}/resource_descriptions/#{id}.xml"
    resp = last_response.body
    resp.should_not match(/australia/)
  end


  it "includes unpublished records in EAD exports upon request" do

    resource = create(:json_resource)
    id = resource.id

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = create(:json_archival_object, {:title => "archival object: #{name}",
                                          :resource => {:ref => resource.uri}})

      if not aos.empty?
        ao.parent = {:ref => aos.last.uri}
        ao.publish = false
      end

      ao.save
      aos << ao
    end

    get "/repositories/#{$repo_id}/resource_descriptions/#{id}.xml?include_unpublished=true"
    resp = last_response.body
    resp.should match(/australia/)
    resp.should match(/audience=\"internal\"/)
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
    resp.should match(/<title>#{dig.title}<\/title>/)
  end


  it "gives you metadata for any kind of export" do
    # agent exports
    agent = create(:json_agent_person).id
    check_metadata("archival_contexts/people/#{agent}.xml")
    agent = create(:json_agent_family).id
    check_metadata("archival_contexts/families/#{agent}.xml")
    agent = create(:json_agent_corporate_entity).id
    check_metadata("archival_contexts/corporate_entities/#{agent}.xml")
    agent = create(:json_agent_software).id
    check_metadata("archival_contexts/softwares/#{agent}.xml")

    # resource exports
    res = create(:json_resource, :publish => true).id
    check_metadata("resource_descriptions/#{res}.xml")
    check_metadata("resources/marc21/#{res}.xml")
    check_metadata("resource_labels/#{res}.tsv")

    # digital object exports
    dig = create(:json_digital_object).id
    check_metadata("digital_objects/mods/#{dig}.xml")
    check_metadata("digital_objects/mets/#{dig}.xml")
    check_metadata("digital_objects/dublin_core/#{dig}.xml")
  end


  def check_metadata(export_uri)
    get "/repositories/#{$repo_id}/#{export_uri}/metadata"
    resp = ASUtils.json_parse(last_response.body)
    resp.has_key?('mimetype').should be true
    resp.has_key?('filename').should be true
  end

end
