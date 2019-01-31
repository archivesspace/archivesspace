require 'spec_helper'

describe 'Slug controller' do
  describe 'repo_slug_in_URL disabled' do
    before(:all) do
      AppConfig[:repo_slug_in_URL] = false
    end

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
      subject_id      = subject[:uri].split("/")[-1]

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

    it "finds classification_terms by slug for 'classifications' controller and 'terms' action" do
      ct = create(:json_classification_term, :slug => "SlugClassificationTerm")
      ct_id = ct[:uri].split("/")[-1]

      get "/slug?slug=SlugClassificationTerm&controller=classifications&action=term"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq(ct_id)
      expect(response["table"]).to eq("classification_term")
    end

    it "finds agent_persons by slug for 'agents' controller" do
      agent_person = create(:json_agent_person, :slug => "SlugAgentPerson")
      agent_person_id = agent_person[:uri].split("/")[-1]

      get "/slug?slug=SlugAgentPerson&controller=agents&action=show"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq(agent_person_id)
      expect(response["table"]).to eq("agent_person")     
    end

    it "finds agent_familys by slug for 'agents' controller" do
      agent_family = create(:json_agent_family, :slug => "SlugAgentFamily")
      agent_family_id = agent_family[:uri].split("/")[-1]

      get "/slug?slug=SlugAgentFamily&controller=agents&action=show"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq(agent_family_id)
      expect(response["table"]).to eq("agent_family")     
    end

    it "finds agent_corporate_entitys by slug for 'agents' controller" do
      agent_corporate_entity = create(:json_agent_corporate_entity, :slug => "SlugAgentFamily")
      agent_corporate_entity_id = agent_corporate_entity[:uri].split("/")[-1]

      get "/slug?slug=SlugAgentFamily&controller=agents&action=show"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq(agent_corporate_entity_id)
      expect(response["table"]).to eq("agent_corporate_entity")     
    end

    it "finds agent_softwares by slug for 'agents' controller" do
      agent_software = create(:json_agent_software, :slug => "SlugAgentSoftware")
      agent_software_id = agent_software[:uri].split("/")[-1]

      get "/slug?slug=SlugAgentSoftware&controller=agents&action=show"
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

  describe 'repo_slug_in_URL enabled' do
    before(:all) do
      AppConfig[:repo_slug_in_URL] = true
      @repo_json = JSONModel(:repository)
                     .from_hash(:repo_code => "SLUGB",
                                :name => "Repo with a slug",
                                :slug => "sluggie")

      @repo = Repository.create_from_json(@repo_json)
    end

    it "finds resources by slug for 'resources' controller" do
      resource = Resource.create_from_json(
        build(:json_resource, {:slug => "SlugResource"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugResource&controller=resources&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(resource.id)
      expect(response["table"]).to eq("resource")
      expect(response["repo_id"]).to eq(@repo.id)
    end

    it "does not find resource by slug if wrong repo slug specified" do
      resource = Resource.create_from_json(
        build(:json_resource, {:slug => "SlugResource2"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugResource2&controller=resources&action=show&repo_slug=sluggarific"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("resource")
      expect(response["repo_id"]).to eq(-1)     
    end

    it "finds digital_objects by slug for 'objects' controller" do
      dig_obj = DigitalObject.create_from_json(
        build(:json_digital_object, {:slug => "SlugDigitalObject"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugDigitalObject&controller=objects&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(dig_obj.id)
      expect(response["table"]).to eq("digital_object")
      expect(response["repo_id"]).to eq(@repo.id)
    end

     it "does not find digital_objects by slug if wrong repo_id specified" do
      dig_obj = DigitalObject.create_from_json(
        build(:json_digital_object, {:slug => "SlugDigitalObject2"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugDigitalObject2&controller=objects&action=show&repo_slug=slugtastic"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("digital_object")
      expect(response["repo_id"]).to eq(-1)
    end

    it "finds archival_objects by slug for 'objects' controller" do
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, {:slug => "SlugArchivalObject"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugArchivalObject&controller=objects&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(ao.id)
      expect(response["table"]).to eq("archival_object")
      expect(response["repo_id"]).to eq(@repo.id)
    end

    it "does not find archival_objects by slug for 'objects' controller if wrong repo is specified" do
      ao = ArchivalObject.create_from_json(
        build(:json_archival_object, {:slug => "SlugArchivalObject"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugArchivalObject&controller=objects&action=show&repo_slug=slugtastic"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("archival_object")
      expect(response["repo_id"]).to eq(-1)
    end

    it "finds digital_object_components by slug for 'objects' controller" do
      doc = DigitalObjectComponent.create_from_json(
        build(:json_digital_object_component, {:slug => "SlugDOC"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugDOC&controller=objects&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(doc.id)
      expect(response["table"]).to eq("digital_object_component")
      expect(response["repo_id"]).to eq(@repo.id)
    end

    it "does not finds digital_object_components by slug for 'objects' controller if wrong repo is specified" do
      doc = DigitalObjectComponent.create_from_json(
        build(:json_digital_object_component, {:slug => "SlugDOC"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugDOC&controller=objects&action=show&repo_slug=slugnotsnail"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("digital_object_component")
      expect(response["repo_id"]).to eq(-1)
    end

    it "finds accessions by slug for 'accessions' controller" do
      accession = Accession.create_from_json(
        build(:json_accession, {:slug => "SlugAccession"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugAccession&controller=accessions&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(accession.id)
      expect(response["table"]).to eq("accession")
      expect(response["repo_id"]).to eq(@repo.id)
    end

    it "does not find accessions by slug if wrong repo is specified" do
      accession = Accession.create_from_json(
        build(:json_accession, {:slug => "SlugAccession2"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugAccession2&controller=accessions&action=show&repo_slug=slugsational"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("accession")
      expect(response["repo_id"]).to eq(-1)
    end

    it "finds classifications by slug for 'classifications' controller" do
      #classification = create(:json_classification, :slug => "SlugClassification")
      #classification_id = classification[:uri].split("/")[-1]

      classification = Classification.create_from_json(
        build(:json_classification, {:slug => "SlugClassification"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugClassification&controller=classifications&action=show&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(classification.id)
      expect(response["table"]).to eq("classification")
      expect(response["repo_id"]).to eq(@repo.id)
    end

    it "does not find classifications by slug if the wrong repo is specified" do
      classification = Classification.create_from_json(
        build(:json_classification, {:slug => "SlugClassification2"}), 
          :repo_id => @repo.id
      )

      get "/slug_with_repo?slug=SlugClassification2&controller=classifications&action=show&repo_slug=slugger"
      response = JSON.parse(last_response.body)

      expect(response["id"]).to eq(-1)
      expect(response["table"]).to eq("classification")
      expect(response["repo_id"]).to eq(-1)
    end

    it "finds classification_terms by slug for 'classifications' controller and 'terms' action" do
      ct = create(:json_classification_term, :slug => "SlugClassificationTerm")
      ct_id = ct[:uri].split("/")[-1]

      # find our repository, and give it a slug.
      # for classification_terms, specifing a repo_id in the constructor hash doesn't work.
      repo_id = ct[:repository]["ref"].split("/")[-1].to_i
      repo = Repository[repo_id]
      repo.update(:slug => "black_slug")

      get "/slug_with_repo?slug=SlugClassificationTerm&controller=classifications&action=term&repo_slug=black_slug"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq(ct_id)
      expect(response["table"]).to eq("classification_term")
      expect(response["repo_id"]).to eq(repo_id)
    end

    it "does not find classification_terms by slug if wrong repo is specified" do
      ct = create(:json_classification_term, :slug => "SlugClassificationTerm")
      ct_id = ct[:uri].split("/")[-1]


      # find our repository, and give it a slug.
      # for classification_terms, specifing a repo_id in the constructor hash doesn't work.
      repo_id = ct[:repository]["ref"].split("/")[-1].to_i
      repo = Repository[repo_id]
      repo.update(:slug => "black_slug")

      get "/slug_with_repo?slug=SlugClassificationTerm&controller=classifications&action=term&repo_slug=sluggie"
      response = JSON.parse(last_response.body)

      expect(response["id"].to_s).to eq("-1")
      expect(response["table"]).to eq("classification_term")
      expect(response["repo_id"]).to eq(-1)
    end
  end
end

