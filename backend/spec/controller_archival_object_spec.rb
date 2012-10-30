require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    create(:repo)
  end


  it "lets you create an archival object and get it back" do
    opts = {:title => 'The archival object title'}
    
    created = create(:json_archival_object, opts).id
    JSONModel(:archival_object).find(created).title.should eq(opts[:title])
  end

  it "returns nil if the archival object is not in this repository" do
    created = create(:json_archival_object).id

    repo = create(:repo, :repo_code => 'OTHERREPO')
    JSONModel(:archival_object).find(created).should eq nil
  end

  it "lets you list all archival objects" do
    create_list(:json_archival_object, 5)
    JSONModel(:archival_object).all.count.should eq(5)
  end


  it "lets you create archival object with a parent" do
    
    resource = create(:json_resource)

    parent = create(:json_archival_object, :resource => resource.uri)
    
    child = create(:json_archival_object, {:title => 'Child', :parent => parent.uri, :resource => resource.uri})

    get "#{$repo}/archival_objects/#{parent.id}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]['title'].should eq('Child')
  end


  it "enforces uniqueness of ref_ids within a Resource" do
    alpha = create(:json_resource)

    beta = create(:json_resource)

    opts = {:ref_id => 'xyz'}

    create(:json_archival_object, opts.merge(:resource => alpha.uri))
    
    expect { 
      create(:json_archival_object, opts.merge(:resource => beta.uri))
    }.to_not raise_error

    expect { 
      create(:json_archival_object, opts.merge(:resource => alpha.uri))
    }.to raise_error
  end


  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    ao = JSONModel(:archival_object).from_hash("ref_id" => "abc")
    ao.save

    known_warnings = ["title"]

    (known_warnings - ao._exceptions[:warnings].keys).should eq([])
    JSONModel::strict_mode(true)
  end


  it "handles updates for an existing archival object" do
    created = create(:json_archival_object)
    
    opts = {:title => 'A brand new title'}

    ao = JSONModel(:archival_object).find(created.id)
    ao.title = opts[:title]
    ao.save

    JSONModel(:archival_object).find(created.id).title.should eq(opts[:title])
  end
  

  it "lets you create an archival object with a subject" do
    vocab = create(:json_vocab)

    subject = create(:json_subject, {:terms => [build(:json_term, :vocabulary => vocab.uri).to_hash], :vocabulary => vocab.uri})

    created = create(:json_archival_object, :subjects => [subject.uri])

    JSONModel(:archival_object).find(created.id).subjects[0].should eq(subject.uri)
  end


  it "can resolve subjects for you" do
    vocab = create(:json_vocab)
    
    opts = {:term => generate(:term)}

    subject = create(:json_subject, {:terms => 
                                        [build(
                                          :json_term, 
                                          opts.merge(:vocabulary => vocab.uri)
                                          ).to_hash
                                        ], 
                                     :vocabulary => vocab.uri})

    created = create(:json_archival_object, :subjects => [subject.uri])

    ao = JSONModel(:archival_object).find(created.id, "resolve[]" => "subjects")

    ao['resolved']['subjects'][0]["terms"][0]["term"].should eq(opts[:term])
  end


  it "can link to an agent" do
    agent = JSONModel(:agent_person).
      from_hash("agent_type" => "agent_person",
                "names" => [{
                              "rules" => "local",
                              "primary_name" => "Magus Magoo",
                              "sort_name" => "Magoo, Mr M",
                              "direct_order" => "standard"
                            }])

    agent.save

    created = create_archival_object("ref_id" => "4567",
                                     "linked_agents" => [{
                                        "ref" => agent.uri,
                                        "role" => "creator"
                                      }],
                                     "title" => "my archival object")

    ao = JSONModel(:archival_object).find(created, "resolve[]" => "ref")
    ao['linked_agents'].length.should eq(1)
    ao['linked_agents'][0]['role'].should eq("creator")
    ao['linked_agents'][0]['resolved']['ref']['sort_name'].should eq("Magoo, Mr M")
  end
end
