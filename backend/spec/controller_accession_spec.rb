require 'spec_helper'


describe 'Accession controller' do

  it "lets you create an accession and get it back" do
    opts = {:title => 'The accession title'}

    id = create(:json_accession, opts).id
    expect(JSONModel(:accession).find(id).title).to eq(opts[:title])
  end


  it "lets you list all accessions" do
    create(:json_accession)
    expect(JSONModel(:accession).all(:page => 1)['results'].count).to eq(1)
  end


  it "fails when you try to update an accession that doesn't exist" do
    acc = build(:json_accession)
    acc.uri = "#{$repo}/accessions/9999"

    expect { acc.save }.to raise_error(RecordNotFound)
  end


  it "uses dummy date when missing accession date" do
    expect(JSONModel(:accession).from_hash("id_0" => "abcdef").accession_date).to eq('9999-12-31')
  end


  it "supports updates" do
    acc = create(:json_accession)

    acc.id_1 = "5678"
    acc.save

    expect(JSONModel(:accession).find(acc.id).id_1).to eq("5678")
  end


  it "knows its own URI" do
    acc = create(:json_accession)
    expect(JSONModel(:accession).find(acc.id).uri).to eq("#{$repo}/accessions/#{acc.id}")
  end


  it "won't let you overwrite the current version of a record with a stale copy" do

    acc = create(:json_accession)

    acc1 = JSONModel(:accession).find(acc.id)
    acc2 = JSONModel(:accession).find(acc.id)

    acc1.id_1 = "5678"
    acc1.save

    # Working off the stale copy
    acc2.id_1 = "9999"
    expect {
      acc2.save
    }.to raise_error(ConflictException)

  end


  it "creates an accession with a language and script of description" do
    opts = {:language => 'eng', :script => 'Latn'}

    id = create(:json_accession, opts).id
    expect(JSONModel(:accession).find(id).language).to eq(opts[:language])
    expect(JSONModel(:accession).find(id).script).to eq(opts[:script])
  end


  it "doesn't let you create an accession with an invalid language" do
    expect {
      create(:json_accession,
             :language => "klingon")
    }.to raise_error(JSONModel::ValidationException)
  end


  it "creates an accession with a rights statement" do
    acc = JSONModel(:accession).from_hash("id_0" => "1234",
                                          "title" => "The accession title",
                                          "content_description" => "The accession description",
                                          "condition_description" => "The condition description",
                                          "accession_date" => "2012-05-03",
                                          "rights_statements" => [
                                            {
                                              "identifier" => "abc123",
                                              "rights_type" => "copyright",
                                              "status" => "copyrighted",
                                              "jurisdiction" => "AU",
                                              "start_date" => "1999-01-01",
                                            }
                                          ]).save
    expect(JSONModel(:accession).find(acc).rights_statements.length).to eq(1)
    expect(JSONModel(:accession).find(acc).rights_statements[0]["identifier"]).to eq("abc123")
  end


  it "creates an accession with a deaccession" do
    acc = JSONModel(:accession).from_hash("id_0" => "1234",
                                          "title" => "The accession title",
                                          "content_description" => "The accession description",
                                          "condition_description" => "The condition description",
                                          "accession_date" => "2012-05-03",
                                          "deaccessions" => [
                                            {
                                              "scope" => "whole",
                                              "description" => "A description of this deaccession",
                                              "date" => {
                                                            "date_type" => "single",
                                                            "label" => "deaccession",
                                                            "begin" => "2012-05-14",
                                                          },
                                            }
                                          ]).save
    expect(JSONModel(:accession).find(acc).deaccessions.length).to eq(1)
    expect(JSONModel(:accession).find(acc).deaccessions[0]["scope"]).to eq("whole")
    expect(JSONModel(:accession).find(acc).deaccessions[0]["date"]["begin"]).to eq("2012-05-14")
  end


  it "doesn't show accessions for other repositories when listing " do
    create(:json_accession)
    expect(JSONModel(:accession).all(:page => 1)['results'].count).to eq(1)

    create(:repo)
    expect(JSONModel(:accession).all(:page => 1)['results'].count).to eq(0)
  end


  it "paginates record listings" do
    10.times { create(:json_accession) }

    page1_ids = JSONModel(:accession).all(:page => 1, :page_size => 5)['results'].map {|obj| obj.id}
    page2_ids = JSONModel(:accession).all(:page => 2, :page_size => 5)['results'].map {|obj| obj.id}

    expect(page1_ids.length).to eq(5)
    expect(page2_ids.length).to eq(5)

    # No overlaps between the contents of our two pages
    expect((page1_ids - page2_ids).length).to eq(5)
  end


  it "supports listing accessions that have changed since a given timestamp" do

    test_accession = create(:json_accession)
    sleep 1
    ts = Time.now.to_i

    expect(JSONModel(:accession).all(:page => 1, :modified_since => ts)['results'].count).to eq(0)

    test_accession.save

    expect(JSONModel(:accession).all(:page => 1, :modified_since => ts)['results'].count).to eq(1)
  end


  it "lets you create an accession with a language of materials" do

    opts = {:language_and_script => {:language => generate(:language)}}

    lang_materials = [build(:json_lang_material, opts)]

    accession = create(:json_accession, :lang_materials => lang_materials)

    expect(JSONModel(:accession).find(accession.id).lang_materials[0]['language_and_script']['language'].length).to eq(3)
    expect(JSONModel(:accession).find(accession.id).lang_materials[0]['notes']).to eq([])
  end


  it "lets you create an accession with a language of materials note" do
    lang_materials = [build(:json_lang_material_with_note)]
    accession = create(:json_accession, :lang_materials => lang_materials)

    expect(JSONModel(:accession).find(accession.id).lang_materials[0]['notes'][0]['content']).not_to be_nil
  end


  it "allows accessions to be created with an agent link" do

    agent1 = create(:json_agent_person)
    agent2 = create(:json_agent_person)

    accession = Accession.create_from_json(build(:json_accession,
                                                 :linked_agents => [
                                                                    {
                                                                      "role" => 'creator',
                                                                      "ref" => agent1.uri,
                                                                      "title" => "the title",
                                                                      "is_primary" => true,
                                                                    },
                                                                    {
                                                                      "role" => 'creator',
                                                                      "ref" => agent2.uri
                                                                    }
                                                                   ]
                                                 ),
                                           :repo_id => $repo_id)
    acc = JSONModel(:accession).find(accession.id)

    expect(acc.linked_agents.length).to eq(2)
    expect(acc.linked_agents[0]['ref']).to eq(agent1.uri)
    expect(acc.linked_agents[1]['ref']).to eq(agent2.uri)
    expect(acc.linked_agents[0]['is_primary']).to be true
    expect(acc.linked_agents[1]['is_primary']).to be false
    expect(acc.linked_agents[0]['title']).to eq('the title')
  end

  it "only allows one 'is_primary' linked agent" do
    agent1 = create(:json_agent_person)
    agent2 = create(:json_agent_person)

    json = build(:json_accession,
                  :linked_agents => [
                    {
                      "role" => 'creator',
                      "ref" => agent1.uri,
                      "title" => "the title",
                      "is_primary" => true,
                    },
                    {
                      "role" => 'creator',
                      "ref" => agent2.uri,
                      "is_primary" => true,
                    }
                                                                   ]
                 )
    expect {
      Accession.create_from_json(json, :repo_id => $repo_id)
    }.to raise_error(Sequel::ValidationFailed)
  end

  it "supports saving and retrieving external IDs" do
    accession = create(:json_accession,
                       :external_ids => [{
                                           'source' => 'brain',
                                           'external_id' => '12345'
                                         }])

    expect(JSONModel(:accession).find(accession.id).external_ids[0]['source']).to eq('brain')
  end


  it "allows accessions to be deleted" do
    resource = create(:json_resource)

    accession = create(:json_accession,
                       :external_ids => [{
                                           'source' => 'brain',
                                           'external_id' => '12345'
                                         }],
                       :deaccessions => [build(:json_deaccession,
                                               :extents => [build(:json_extent)])],
                       :related_resources => [{'ref' => resource.uri}])

    resource = JSONModel(:resource).find(resource.id)
    resource.related_accessions = [{'ref' => accession.uri}]
    resource.save

    accession.delete

    expect {
      JSONModel(:accession).find(accession.id)
    }.to raise_error(RecordNotFound)

    resource = JSONModel(:resource).find(resource.id)
    expect(resource).not_to be_nil
    expect(resource.related_accessions.count).to be(0)
  end


end
