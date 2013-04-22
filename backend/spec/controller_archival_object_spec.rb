require 'spec_helper'

describe 'Archival Object controller' do

  it "lets you create an archival object and get it back" do
    internal_only = [true, false].sample
    opts = {:title => 'The archival object title', :internal_only => internal_only}
    
    created = create(:json_archival_object, opts).id
    JSONModel(:archival_object).find(created).title.should eq(opts[:title])
    JSONModel(:archival_object).find(created).internal_only.should eq(opts[:internal_only])
  end

  it "returns nil if the archival object is not in this repository" do
    created = create(:json_archival_object).id

    repo = create(:repo, :repo_code => 'OTHERREPO')

    expect {
      JSONModel(:archival_object).find(created)
    }.to raise_error(RecordNotFound)
  end

  it "lets you list all archival objects" do
    create_list(:json_archival_object, 5)
    JSONModel(:archival_object).all(:page => 1)['results'].count.should eq(5)
  end


  it "lets you reorder sibling archival objects" do
    
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1")
    ao_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO2")
    ao_3 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO3")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO1")
    tree.children[1]["title"].should eq("AO2")
    tree.children[2]["title"].should eq("AO3")

    ao_1 = JSONModel(:archival_object).find(ao_1.id)
    ao_1.position = 1  # the second position
    ao_1.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO2")
    tree.children[1]["title"].should eq("AO1")
    tree.children[2]["title"].should eq("AO3")
  end


  it "enforces uniqueness of ref_ids within a Resource" do
    alpha = create(:json_resource)

    beta = create(:json_resource)

    opts = {:ref_id => 'xyz'}

    create(:json_archival_object, opts.merge(:resource => {:ref => alpha.uri}))
    
    expect { 
      create(:json_archival_object, opts.merge(:resource => {:ref => beta.uri}))
    }.to_not raise_error

    expect { 
      create(:json_archival_object, opts.merge(:resource => {:ref => alpha.uri}))
    }.to raise_error
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

    subject = create(:json_subject, {:terms => [build(:json_term, :vocabulary => vocab.uri)], :vocabulary => vocab.uri})

    created = create(:json_archival_object, :subjects => [{:ref => subject.uri}])

    JSONModel(:archival_object).find(created.id).subjects[0]['ref'].should eq(subject.uri)
  end


  it "can resolve subjects for you" do
    vocab = create(:json_vocab)
    
    opts = {:term => generate(:term)}

    subject = create(:json_subject, {:terms => 
                                        [build(
                                          :json_term, 
                                          opts.merge(:vocabulary => vocab.uri)
                                          )
                                        ], 
                                     :vocabulary => vocab.uri})

    created = create(:json_archival_object, :subjects => [{:ref => subject.uri}])

    ao = JSONModel(:archival_object).find(created.id, "resolve[]" => "subjects")

    ao['subjects'][0]['_resolved']["terms"][0]["term"].should eq(opts[:term])
  end


  it "will won't allow a ref_id to be changed upon update" do
    created =  create(:json_archival_object, "ref_id" => nil)

    ao = JSONModel(:archival_object).find(created.id)
    ref_id = ao.ref_id

    ref_id.should_not be_nil

    ao.ref_id = "foo"
    ao.save

    JSONModel(:archival_object).find(created.id).ref_id.should eq(ref_id)
  end


  it "lets you create archival object with a parent" do

    resource = create(:json_resource)

    parent = create(:json_archival_object, :resource => {:ref => resource.uri})

    child = create(:json_archival_object, {
                     :title => 'Child',
                     :parent => {:ref => parent.uri},
                     :resource => {:ref => resource.uri}
                   })

    get "#{$repo}/archival_objects/#{parent.id}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]['title'].should eq('Child')
  end


  it "will have the auto-generated ref_id refetched upon save" do
    archival_object = build(:json_archival_object, "ref_id" => nil)

    archival_object.ref_id.should be_nil

    archival_object.save

    archival_object.ref_id.should_not be_nil
  end



  it "will have the auto-generated rights identifier refetched upon save" do
    archival_object = build(:json_archival_object, {
                                                      :rights_statements => [
                                                                              build(:json_rights_statement, {:identifier => nil})
                                                                            ]
                                                   })

    archival_object.rights_statements[0]["identifier"].should be_nil

    archival_object.save

    archival_object.rights_statements[0]["identifier"].should_not be_nil
  end


  it "will re-resolve the subrecords upon refetch" do
    vocab = create(:json_vocab)
    opts = {:term => generate(:term)}
    subject = create(:json_subject, {:terms =>
                                       [build(
                                          :json_term,
                                          opts.merge(:vocabulary => vocab.uri)
                                        )
                                       ],
                                     :vocabulary => vocab.uri})
    created = create(:json_archival_object, :subjects => [{:ref => subject.uri}])


    ao = JSONModel(:archival_object).find(created.id, "resolve[]" => "subjects")

    ao['subjects'][0]['_resolved']["terms"][0]["term"].should eq(opts[:term])

    ao.refetch

    ao['subjects'][0]['_resolved']["terms"][0]["term"].should eq(opts[:term])
  end


  it "can store some (really long!) notes and get them back" do
    archival_object = create(:json_archival_object)

    notes = build(:json_note_bibliography, 'content' => ["x" * 40000])

    archival_object.notes = [notes]
    archival_object.save

    JSONModel(:archival_object).find(archival_object.id)[:notes].first.should eq(notes.to_hash)
  end


  it "allows some non-alphanumeric characters in ref_ids" do
    ref_id = ':crazy.times:'
    ao = create(:json_archival_object, :ref_id => ref_id)

    JSONModel(:archival_object).find(ao.id)[:ref_id].should eq(ref_id)
  end

end
