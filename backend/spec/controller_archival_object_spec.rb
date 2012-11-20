require 'spec_helper'

describe 'Archival Object controller' do

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
    JSONModel(:archival_object).all(:page => 1)['results'].count.should eq(5)
  end


  it "lets you reorder sibling archival objects" do
    
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => resource.uri, :title=> "AO1")
    ao_2 = create(:json_archival_object, :resource => resource.uri, :title=> "AO2")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO1")
    tree.children[1]["title"].should eq("AO2")

    ao_1 = JSONModel(:archival_object).find(ao_1.id)
    ao_1.position = 1
    ao_1.save


    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO2")
    tree.children[1]["title"].should eq("AO1")
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


  it "will won't allow a ref_id to be changed upon update" do
    created =  create(:json_archival_object, "ref_id" => nil)

    JSONModel(:archival_object).find(created.id).ref_id.should_not be_nil
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


  it "will have the auto-generated ref_id refetched upon save" do
    archival_object = build(:json_archival_object, "ref_id" => nil)

    archival_object.ref_id.should be_nil

    archival_object.save

    archival_object.ref_id.should_not be_nil
  end



  it "will have the auto-generated rights identifier refetched upon save" do
    archival_object = build(:json_archival_object, {
                                                      :rights_statements => [
                                                                              build(:json_rights_statement, {:identifier => nil}).to_hash
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
                                        ).to_hash
                                       ],
                                     :vocabulary => vocab.uri})
    created = create(:json_archival_object, :subjects => [subject.uri])


    ao = JSONModel(:archival_object).find(created.id, "resolve[]" => "subjects")

    ao['resolved']['subjects'][0]["terms"][0]["term"].should eq(opts[:term])

    ao.refetch

    ao['resolved']['subjects'][0]["terms"][0]["term"].should eq(opts[:term])
  end

end
