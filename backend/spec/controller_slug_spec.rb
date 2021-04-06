require 'spec_helper'

describe 'Slug controller' do
  it "finds repository by slug for 'repositories' controller" do
    repo = Repository.create_from_json(JSONModel(:repository)
                      .from_hash(:repo_code => "SLUG",
                                :name => "Repo with a slug",
                                :slug => "sluggy"))


    get "/slug?slug=sluggy&controller=repositories&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"]).to eq(repo[:id])
    expect(response["table"]).to eq("repository")
  end

  it "finds resources by slug for 'resources' controller" do
    resource = create(:json_resource, :slug => "SlugResource")
    resource_id      = resource[:uri].split("/")[-1]
    resource_repo_id = resource[:uri].split("/")[2]

    get "/slug?slug=SlugResource&controller=resources&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(resource_id)
    expect(response["table"]).to eq("resource")
    expect(response["repo_id"].to_s).to eq(resource_repo_id)
  end

  it "finds digital_objects by slug for 'objects' controller" do
    dig_obj = create(:json_digital_object, :slug => "SlugDigitalObject")
    dig_obj_id      = dig_obj[:uri].split("/")[-1]
    dig_obj_repo_id = dig_obj[:uri].split("/")[2]

    get "/slug?slug=SlugDigitalObject&controller=objects&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(dig_obj_id)
    expect(response["table"]).to eq("digital_object")
    expect(response["repo_id"].to_s).to eq(dig_obj_repo_id)
  end

  it "finds accessions by slug for 'accessions' controller" do
    accession = create(:json_accession, :slug => "SlugAccession")
    accession_repo_id = accession[:uri].split("/")[2]
    accession_id      = accession[:uri].split("/")[-1]

    get "/slug?slug=SlugAccession&controller=accessions&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(accession_id)
    expect(response["table"]).to eq("accession")
    expect(response["repo_id"].to_s).to eq(accession_repo_id)
  end

  it "finds subjects by slug for 'subjects' controller" do
    subject = create(:json_subject, :slug => "SlugSubject")
    subject_id = subject[:uri].split("/")[-1]

    get "/slug?slug=SlugSubject&controller=subjects&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(subject_id)
    expect(response["table"]).to eq("subject")
  end

  it "finds classifications by slug for 'classifications' controller" do
    classification = create(:json_classification, :slug => "SlugClassification")
    classification_id = classification[:uri].split("/")[-1]

    get "/slug?slug=SlugClassification&controller=classifications&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(classification_id)
    expect(response["table"]).to eq("classification")
  end


  it "finds agent_persons by slug for 'agents' controller" do
    agent_person = create(:json_agent_person, :slug => "SlugAgentPerson", :is_slug_auto => false)
    agent_person_id = agent_person[:uri].split("/")[-1]

    get "/slug?slug=slugagentperson&controller=agents&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(agent_person_id)
    expect(response["table"]).to eq("agent_person")
  end

  it "finds agent_familys by slug for 'agents' controller" do
    agent_family = create(:json_agent_family, :slug => "SlugAgentFamily", :is_slug_auto => false)
    agent_family_id = agent_family[:uri].split("/")[-1]

    get "/slug?slug=slugagentfamily&controller=agents&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(agent_family_id)
    expect(response["table"]).to eq("agent_family")
  end

  it "finds agent_corporate_entitys by slug for 'agents' controller" do
    agent_corporate_entity = create(:json_agent_corporate_entity, :slug => "SlugAgentFamily", :is_slug_auto => false)
    agent_corporate_entity_id = agent_corporate_entity[:uri].split("/")[-1]

    get "/slug?slug=slugagentfamily&controller=agents&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(agent_corporate_entity_id)
    expect(response["table"]).to eq("agent_corporate_entity")
  end

  it "finds agent_softwares by slug for 'agents' controller" do
    agent_software = create(:json_agent_software, :slug => "SlugAgentSoftware", :is_slug_auto => false)
    agent_software_id = agent_software[:uri].split("/")[-1]

    get "/slug?slug=slugagentsoftware&controller=agents&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"].to_s).to eq(agent_software_id)
    expect(response["table"]).to eq("agent_software")
  end

  it "finds archival_objects by slug for 'objects' controller" do
    ao = ArchivalObject.create_from_json(
      build(:json_archival_object, {:slug => "SlugArchivalObject"})
    )

    get "/slug?slug=SlugArchivalObject&controller=objects&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"]).to eq(ao.id)
    expect(response["table"]).to eq("archival_object")
  end

  it "finds digital_object_components by slug for 'objects' controller" do
    doc = DigitalObjectComponent.create_from_json(
      build(:json_digital_object_component, {:slug => "SlugDOC"})
    )

    get "/slug?slug=SlugDOC&controller=objects&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"]).to eq(doc.id)
    expect(response["table"]).to eq("digital_object_component")
  end
end
