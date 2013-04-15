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

    expect { acc.save }.to raise_error
  end


  it "fails on missing properties" do
    JSONModel::strict_mode(false)

    expect { JSONModel(:accession).from_hash("id_0" => "abcdef") }.to raise_error(JSONModel::ValidationException)

    begin
      acc = JSONModel(:accession).from_hash("id_0" => "abcdef")
    rescue JSONModel::ValidationException => e
      errors = ["title", "accession_date"]
      warnings = ["content_description", "condition_description"]

      (e.errors.keys - errors).should eq([])
      (e.warnings.keys - warnings).should eq([])
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
                                              "rights_type" => "intellectual_property",
                                              "ip_status" => "copyrighted",
                                              "jurisdiction" => "AU",
                                            }
                                          ]).save
    JSONModel(:accession).find(acc).rights_statements.length.should eq(1)
    JSONModel(:accession).find(acc).rights_statements[0]["identifier"].should eq("abc123")
    JSONModel(:accession).find(acc).rights_statements[0]["active"].should eq(true)
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


  it "can suppress an accession and then unsuppress it" do
    accession = create(:json_accession)
    accession.suppress
    accession.suppressed.should eq(true)
    JSONModel(:accession).find(accession.id).suppressed.should eq(true)
    accession.unsuppress
    accession.suppressed.should eq(false)
    JSONModel(:accession).find(accession.id).suppressed.should eq(false)
  end


  it "doesn't show suppressed accessions when listing" do
    3.times do
      create(:json_accession)
    end

    create_nobody_user

    accession = create(:json_accession)
    accession.suppress

    as_test_user('nobody') do
      JSONModel(:accession).all(:page => 1)['results'].count.should eq(3)
    end
  end


  it "doesn't give you any schtick if you request a suppressed accession as a manager" do
    accession = create(:json_accession)
    accession.suppress

    returned_accession = JSONModel(:accession).find(accession.id)

    returned_accession.suppressed.should eq(true)
  end


  it "(un)suppresses events that link solely to a (un)suppressed accession" do
    test_agent = create(:json_agent_person)
    test_accession = create(:json_accession)

    event = create(:json_event,
                   :linked_agents => [{
                                        'ref' => test_agent.uri,
                                        'role' => generate(:agent_role)
                                      }],
                   :linked_records => [{
                                         'ref' => test_accession.uri,
                                         'role' => generate(:record_role)
                                       }])

    create_nobody_user

    as_test_user('nobody') do
      JSONModel(:event).find(event.id).should_not be(nil)
    end

    # Suppressing the accession suppresses the event too
    test_accession.suppress

    as_test_user('nobody') do
      expect {
        JSONModel(:event).find(event.id)
      }.to raise_error(RecordNotFound)
    end


    # and unsuppressing the accession unsuppresses the event
    test_accession.unsuppress

    as_test_user('nobody') do
      JSONModel(:event).find(event.id).should_not be(nil)
    end



  end


  it "prevents updates to suppressed accession records" do
    test_accession = create(:json_accession)

    test_accession.suppress

    test_accession = JSONModel(:accession).find(test_accession.id)
    test_accession.title = "A new update"

    expect {
      test_accession.save
    }.to raise_error(ReadOnlyException)
  end


  it "prevents a regular update user from changing a record's suppression" do
    test_accession = create(:json_accession)

    create_nobody_user
    archivists = JSONModel(:group).all(:group_code => "repository-archivists").first
    archivists.member_usernames = ['nobody']
    archivists.save

    expect {
      as_test_user('nobody') do
        test_accession.suppress
      end
    }.to raise_error(AccessDeniedException)

    test_accession.suppress

    expect {
      as_test_user('nobody') do
        test_accession.unsuppress
      end
    }.to raise_error(AccessDeniedException)

    test_accession.unsuppress

    # Sneaky side attack by setting the attribute directly
    as_test_user('nobody') do
      test_accession = JSONModel(:accession).find(test_accession.id)
      test_accession["suppressed"] = true
      test_accession.save

      # Attempted change to suppress status got ignored
      JSONModel(:accession).find(test_accession.id).should_not eq(nil)
    end
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


  it "can return a list of all related resources" do
    resource = create(:json_resource)
    accession = create(:json_accession)

    resource.related_accessions = [{'ref' => accession.uri}]
    resource.save

    JSONModel(:resource).find(resource.id).related_accessions[0]['ref'].should eq(accession.uri)

    # Now query the tree
    tree = JSONModel(:accession_tree).find(nil, :accession_id => accession.id)
    tree.title.should eq(accession.title)
    tree.children.count.should eq(1)
    tree.children[0]['title'].should eq(resource.title)
    tree.children[0]['record_uri'].should eq(resource.uri)
  end


  it "allows accessions to be created with an agent link" do

    agent1 = create(:json_agent_person)
    agent2 = create(:json_agent_person)

    accession = Accession.create_from_json(build(:json_accession,
                                                 :linked_agents => [
                                                                    {
                                                                      "role" => 'creator',
                                                                      "ref" => agent1.uri
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
