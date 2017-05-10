require 'spec_helper'


describe 'Accession controller' do

  it "lets you create an accession and get it back" do
    opts = {:title => 'The accession title'}

    id = create(:json_accession, opts).id
    JSONModel(:accession).find(id).title.should eq(opts[:title])
  end


  it "lets you list all accessions" do
    create(:json_accession)
    JSONModel(:accession).all(:page => 1)['results'].count.should eq(1)
  end


  it "fails when you try to update an accession that doesn't exist" do
    acc = build(:json_accession)
    acc.uri = "#{$repo}/accessions/9999"

    expect { acc.save }.to raise_error(RecordNotFound)
  end


  it "fails on missing properties" do
    JSONModel::strict_mode(false)

    expect { JSONModel(:accession).from_hash("id_0" => "abcdef") }.to raise_error(JSONModel::ValidationException)

    begin
      acc = JSONModel(:accession).from_hash("id_0" => "abcdef")
    rescue JSONModel::ValidationException => e
      errors = ["accession_date"]
      (e.errors.keys.sort.should eq(errors.sort))
    end

    JSONModel::strict_mode(true)
  end


  it "supports updates" do
    acc = create(:json_accession)

    acc.id_1 = "5678"
    acc.save

    JSONModel(:accession).find(acc.id).id_1.should eq("5678")
  end


  it "knows its own URI" do
    acc = create(:json_accession)
    JSONModel(:accession).find(acc.id).uri.should eq("#{$repo}/accessions/#{acc.id}")
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
    JSONModel(:accession).find(acc).rights_statements.length.should eq(1)
    JSONModel(:accession).find(acc).rights_statements[0]["identifier"].should eq("abc123")
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
    JSONModel(:accession).find(acc).deaccessions.length.should eq(1)
    JSONModel(:accession).find(acc).deaccessions[0]["scope"].should eq("whole")
    JSONModel(:accession).find(acc).deaccessions[0]["date"]["begin"].should eq("2012-05-14")
  end


  it "doesn't show accessions for other repositories when listing " do
    create(:json_accession)
    JSONModel(:accession).all(:page => 1)['results'].count.should eq(1)

    create(:repo)
    JSONModel(:accession).all(:page => 1)['results'].count.should eq(0)
  end


  it "paginates record listings" do
    10.times { create(:json_accession) }

    page1_ids = JSONModel(:accession).all(:page => 1, :page_size => 5)['results'].map {|obj| obj.id}
    page2_ids = JSONModel(:accession).all(:page => 2, :page_size => 5)['results'].map {|obj| obj.id}

    page1_ids.length.should eq(5)
    page2_ids.length.should eq(5)

    # No overlaps between the contents of our two pages
    (page1_ids - page2_ids).length.should eq(5)
  end


  it "supports listing accessions that have changed since a given timestamp" do

    test_accession = create(:json_accession)
    sleep 1
    ts = Time.now.to_i

    JSONModel(:accession).all(:page => 1, :modified_since => ts)['results'].count.should eq(0)

    test_accession.save

    JSONModel(:accession).all(:page => 1, :modified_since => ts)['results'].count.should eq(1)
  end


  it "allows accessions to be created with an agent link" do

    agent1 = create(:json_agent_person)
    agent2 = create(:json_agent_person)

    accession = Accession.create_from_json(build(:json_accession,
                                                 :linked_agents => [
                                                                    {
                                                                      "role" => 'creator',
                                                                      "ref" => agent1.uri,
                                                                      "title" => "the title"
                                                                    },
                                                                    {
                                                                      "role" => 'creator',
                                                                      "ref" => agent2.uri
                                                                    }
                                                                   ]
                                                 ),
                                           :repo_id => $repo_id)

    acc = JSONModel(:accession).find(accession.id)

    acc.linked_agents.length.should eq(2)
    acc.linked_agents[0]['ref'].should eq(agent1.uri)
    acc.linked_agents[1]['ref'].should eq(agent2.uri)

    acc.linked_agents[0]['title'].should eq('the title')
  end


  it "supports saving and retrieving external IDs" do
    accession = create(:json_accession,
                       :external_ids => [{
                                           'source' => 'brain',
                                           'external_id' => '12345'
                                         }])

    JSONModel(:accession).find(accession.id).external_ids[0]['source'].should eq('brain')
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
    resource.should_not eq(nil)
    resource.related_accessions.count.should be(0)
  end


end
