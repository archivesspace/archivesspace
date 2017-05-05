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

    expect {
      JSONModel(:archival_object).find(created)
    }.to raise_error(RecordNotFound)
  end

  it "lets you list all archival objects" do
    create_list(:json_archival_object, 5)
    JSONModel(:archival_object).all(:page => 1)['results'].count.should eq(5)
  end

  it "gives you a better error if a uri is jacked" do
    expect { 
      create(:json_archival_object, :resource => {:ref => "/bad/uri"}, :title => "AO1")
    }.to raise_error(JSONModel::ValidationException)
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


  it "lets you specify your tree position on creation" do
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1")
    ao_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO2")
    ao_3 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO3", :position => 1)

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO1")
    tree.children[1]["title"].should eq("AO3")
    tree.children[2]["title"].should eq("AO2")
  end


  it "doesn't mind if your specified position is greater than the existing max position" do
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1", :position => 1)
    ao_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO2")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children[0]["title"].should eq("AO1")
    tree.children[1]["title"].should eq("AO2")
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
    }.to raise_error(JSONModel::ValidationException)
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

    JSONModel(:archival_object).find(archival_object.id)[:notes].first['content'].should eq(notes.to_hash['content'])
  end


  it "can publish notes" do
    archival_object = create(:json_archival_object)

    notes = [build(:json_note_bibliography, :publish => false),
             build(:json_note_index, :publish => false)]

    archival_object.notes = notes
    archival_object.save

    ArchivalObject[archival_object.id].publish!
    ArchivalObject[archival_object.id].note.all? {|note|
      note.publish == 1
    }.should be_truthy
  end


  it "can publish records with really long notes" do
    archival_object = create(:json_archival_object)

    notes = build(:json_note_bibliography, 'content' => ["x" * 40000])

    archival_object.notes = [notes]
    archival_object.save

    expect {
      ArchivalObject[archival_object.id].publish!
    }.to_not raise_error
  end


  it "allows some non-alphanumeric characters in ref_ids" do
    ref_id = ':crazy.times:'
    ao = create(:json_archival_object, :ref_id => ref_id)

    JSONModel(:archival_object).find(ao.id)[:ref_id].should eq(ref_id)
  end


  it "allows posting of array of children" do
    resource = create(:json_resource)
    parent_archival_object = create(:json_archival_object, :resource => {:ref => resource.uri})

    archival_object_1 = build(:json_archival_object)
    archival_object_2 = build(:json_archival_object)

    children = JSONModel(:archival_record_children).from_hash({
      "children" => [archival_object_1, archival_object_2]
    })

    url = URI("#{JSONModel::HTTP.backend_url}#{parent_archival_object.uri}/children")
    response = JSONModel::HTTP.post_json(url, children.to_json)
    json_response = ASUtils.json_parse(response.body)

    json_response["status"].should eq("Updated")
    get "#{$repo}/archival_objects/#{json_response["id"]}/children"
    last_response.should be_ok

    children = JSON(last_response.body)

    children.length.should eq(2)
    children[0]["title"].should eq(archival_object_1["title"])
    children[0]["parent"]["ref"].should eq(parent_archival_object.uri)
    children[0]["resource"]["ref"].should eq(resource.uri)

    children[1]["title"].should eq(archival_object_2["title"])
    children[1]["parent"]["ref"].should eq(parent_archival_object.uri)
    children[1]["resource"]["ref"].should eq(resource.uri)
  end

  it "lets you create an archival object with an instance with a container with a location (and the location is resolved)" do

    # create the record with all the instance/container etc
    location = create(:json_location, :temporary => generate(:temporary_location_type))
    status = 'current'

    top_container = create(:json_top_container,
                           :container_locations => [{'ref' => location.uri,
                                                      'status' => status,
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}])


    archival_object = create(:json_archival_object,
                             :instances => [build(:json_instance,
                                                  :sub_container => build(:json_sub_container,
                                                                          :top_container => {:ref => top_container.uri}))]
                             )

    obj = JSONModel(:archival_object).find(archival_object.id, "resolve[]" => "top_container::container_locations")

    loc = obj.instances[0]["sub_container"]['top_container']['_resolved']["container_locations"][0]
    loc["status"].should eq(status)
    loc["_resolved"]["building"].should eq(location.building)
  end


  it "accepts move of multiple children" do
    resource = create(:json_resource)
    target = create(:json_archival_object, :resource => {:ref => resource.uri})

    sibling_1 = create(:json_archival_object, :resource => {:ref => resource.uri})
    sibling_2 = create(:json_archival_object, :resource => {:ref => resource.uri})

    response = JSONModel::HTTP::post_form("#{target.uri}/accept_children", {"children[]" => [sibling_1.uri, sibling_2.uri], "position" => 0})
    json_response = ASUtils.json_parse(response.body)

    json_response["status"].should eq("Updated")
    get "#{$repo}/archival_objects/#{target.id}/children"
    last_response.should be_ok

    children = ASUtils.json_parse(last_response.body)

    children.length.should eq(2)
    children[0]["title"].should eq(sibling_1["title"])
    children[0]["parent"]["ref"].should eq(target.uri)
    children[0]["resource"]["ref"].should eq(resource.uri)

    children[1]["title"].should eq(sibling_2["title"])
    children[1]["parent"]["ref"].should eq(target.uri)
    children[1]["resource"]["ref"].should eq(resource.uri)
  end

end
