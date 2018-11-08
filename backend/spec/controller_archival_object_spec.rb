require 'spec_helper'

describe 'Archival Object controller' do

  it "lets you create an archival object and get it back" do
    opts = {:title => 'The archival object title'}

    created = create(:json_archival_object, opts).id
    expect(JSONModel(:archival_object).find(created).title).to eq(opts[:title])
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
    expect(JSONModel(:archival_object).all(:page => 1)['results'].count).to eq(5)
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

    expect(tree.children[0]["title"]).to eq("AO1")
    expect(tree.children[1]["title"]).to eq("AO2")
    expect(tree.children[2]["title"]).to eq("AO3")

    ao_1 = JSONModel(:archival_object).find(ao_1.id)
    ao_1.position = 1  # the second position
    ao_1.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    expect(tree.children[0]["title"]).to eq("AO2")
    expect(tree.children[1]["title"]).to eq("AO1")
    expect(tree.children[2]["title"]).to eq("AO3")
  end


  it "lets you specify your tree position on creation" do
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1")
    ao_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO2")
    ao_3 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO3", :position => 1)

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    expect(tree.children[0]["title"]).to eq("AO1")
    expect(tree.children[1]["title"]).to eq("AO3")
    expect(tree.children[2]["title"]).to eq("AO2")
  end


  it "doesn't mind if your specified position is greater than the existing max position" do
    resource = create(:json_resource)

    ao_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1", :position => 1)
    ao_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO2")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    expect(tree.children[0]["title"]).to eq("AO1")
    expect(tree.children[1]["title"]).to eq("AO2")
  end


  it "enforces uniqueness of ref_ids within a Resource" do
    alpha = create(:json_resource)

    beta = create(:json_resource)

    opts = {:ref_id => 'xyz'}

    create(:json_archival_object, opts.merge(:resource => {:ref => alpha.uri}))

    expect {
      create(:json_archival_object, opts.merge(:resource => {:ref => beta.uri}))
    }.not_to raise_error

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

    expect(JSONModel(:archival_object).find(created.id).title).to eq(opts[:title])
  end


  it "lets you create an archival object with a subject" do
    vocab = create(:json_vocab)

    subject = create(:json_subject, {:terms => [build(:json_term, :vocabulary => vocab.uri)], :vocabulary => vocab.uri})

    created = create(:json_archival_object, :subjects => [{:ref => subject.uri}])

    expect(JSONModel(:archival_object).find(created.id).subjects[0]['ref']).to eq(subject.uri)
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

    expect(ao['subjects'][0]['_resolved']["terms"][0]["term"]).to eq(opts[:term])
  end


  it "will won't allow a ref_id to be changed upon update" do
    created =  create(:json_archival_object, "ref_id" => nil)

    ao = JSONModel(:archival_object).find(created.id)
    ref_id = ao.ref_id

    expect(ref_id).not_to be_nil

    ao.ref_id = "foo"
    ao.save

    expect(JSONModel(:archival_object).find(created.id).ref_id).to eq(ref_id)
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
    expect(last_response).to be_ok

    children = JSON(last_response.body)
    expect(children[0]['title']).to eq('Child')
  end


  it "will have the auto-generated ref_id refetched upon save" do
    archival_object = build(:json_archival_object, "ref_id" => nil)

    expect(archival_object.ref_id).to be_nil

    archival_object.save

    expect(archival_object.ref_id).not_to be_nil
  end



  it "will have the auto-generated rights identifier refetched upon save" do
    archival_object = build(:json_archival_object, {
                                                      :rights_statements => [
                                                                              build(:json_rights_statement, {:identifier => nil})
                                                                            ]
                                                   })

    expect(archival_object.rights_statements[0]["identifier"]).to be_nil

    archival_object.save

    expect(archival_object.rights_statements[0]["identifier"]).not_to be_nil
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

    expect(ao['subjects'][0]['_resolved']["terms"][0]["term"]).to eq(opts[:term])

    ao.refetch

    expect(ao['subjects'][0]['_resolved']["terms"][0]["term"]).to eq(opts[:term])
  end


  it "can store some (really long!) notes and get them back" do
    archival_object = create(:json_archival_object)

    notes = build(:json_note_bibliography, 'content' => ["x" * 40000])

    archival_object.notes = [notes]
    archival_object.save

    expect(JSONModel(:archival_object).find(archival_object.id)[:notes].first['content']).to eq(notes.to_hash['content'])
  end


  it "can publish notes" do
    archival_object = create(:json_archival_object)

    notes = [build(:json_note_bibliography, :publish => false),
             build(:json_note_index, :publish => false)]

    archival_object.notes = notes
    archival_object.save

    ArchivalObject[archival_object.id].publish!
    expect(ArchivalObject[archival_object.id].note.all? {|note|
      note.publish == 1
    }).to be_truthy
  end


  it "can publish records with really long notes" do
    archival_object = create(:json_archival_object)

    notes = build(:json_note_bibliography, 'content' => ["x" * 40000])

    archival_object.notes = [notes]
    archival_object.save

    expect {
      ArchivalObject[archival_object.id].publish!
    }.not_to raise_error
  end


  it "allows some non-alphanumeric characters in ref_ids" do
    ref_id = ':crazy.times:'
    ao = create(:json_archival_object, :ref_id => ref_id)

    expect(JSONModel(:archival_object).find(ao.id)[:ref_id]).to eq(ref_id)
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

    expect(json_response["status"]).to eq("Updated")
    get "#{$repo}/archival_objects/#{json_response["id"]}/children"
    expect(last_response).to be_ok

    children = JSON(last_response.body)

    expect(children.length).to eq(2)
    expect(children[0]["title"]).to eq(archival_object_1["title"])
    expect(children[0]["parent"]["ref"]).to eq(parent_archival_object.uri)
    expect(children[0]["resource"]["ref"]).to eq(resource.uri)

    expect(children[1]["title"]).to eq(archival_object_2["title"])
    expect(children[1]["parent"]["ref"]).to eq(parent_archival_object.uri)
    expect(children[1]["resource"]["ref"]).to eq(resource.uri)
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
    expect(loc["status"]).to eq(status)
    expect(loc["_resolved"]["building"]).to eq(location.building)
  end


  it "accepts move of multiple children" do
    resource = create(:json_resource)
    target = create(:json_archival_object, :resource => {:ref => resource.uri})

    sibling_1 = create(:json_archival_object, :resource => {:ref => resource.uri})
    sibling_2 = create(:json_archival_object, :resource => {:ref => resource.uri})

    response = JSONModel::HTTP::post_form("#{target.uri}/accept_children", {"children[]" => [sibling_1.uri, sibling_2.uri], "position" => 0})
    json_response = ASUtils.json_parse(response.body)

    expect(json_response["status"]).to eq("Updated")
    get "#{$repo}/archival_objects/#{target.id}/children"
    expect(last_response).to be_ok

    children = ASUtils.json_parse(last_response.body)

    expect(children.length).to eq(2)
    expect(children[0]["title"]).to eq(sibling_1["title"])
    expect(children[0]["parent"]["ref"]).to eq(target.uri)
    expect(children[0]["resource"]["ref"]).to eq(resource.uri)

    expect(children[1]["title"]).to eq(sibling_2["title"])
    expect(children[1]["parent"]["ref"]).to eq(target.uri)
    expect(children[1]["resource"]["ref"]).to eq(resource.uri)
  end

end
