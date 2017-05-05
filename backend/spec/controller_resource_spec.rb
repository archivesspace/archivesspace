require 'spec_helper'

describe 'Resources controller' do

  before(:each) do
    create(:repo)
  end


  it "lets you create a resource and get it back" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "dates" => [{  "date_type" => "single", "label" => "creation", "expression" => "1901" }],
                                              "id_0" => "abc123", "level" => "collection", "language" => "eng",
                                              "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    JSONModel(:resource).find(id).title.should eq("a resource")
  end


  it "lets you update a resource" do
    resource = create(:json_resource)

    resource.title = "an updated resource"
    resource.save

    JSONModel(:resource).find(resource.id).title.should eq("an updated resource")
  end


  it "doesn't let you create a resource without a 4-part identifier" do
    expect {
      create(:json_resource,
             :id_0 => nil, :id_1 => nil, :id_2 => nil, :id_3 => nil)
    }.to raise_error(JSONModel::ValidationException)
  end


  it "can handle asking for the tree of an empty resource" do
    resource = create(:json_resource)

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children.length.should eq(0)
  end


  it "lets you query the resource tree of related archival objects" do

    resource = create(:json_resource)
    id = resource.id

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = create(:json_archival_object, {:title => "archival object: #{name}"})
      if not aos.empty?
        ao.parent = {:ref => aos.last.uri}
      end

      ao.resource = {:ref => resource.uri}

      ao.save
      aos << ao
    end

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id).to_hash

    tree['children'][0]['record_uri'].should eq(aos[0].uri)
    tree['children'][0]['children'][0]['record_uri'].should eq(aos[1].uri)
  end


  it "lets you create a resource with a subject" do

    vocab = create(:json_vocab)
    vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)
    subject = create(:json_subject,
                    :terms => [build(:json_term, :vocabulary => vocab_uri)],
                    :vocabulary => vocab_uri
                    )

    resource = create(:json_resource, :subjects => [{:ref => subject.uri}])

    JSONModel(:resource).find(resource.id).subjects[0]['ref'].should eq(subject.uri)
  end


  it "can give a list of all resources" do

    powers = ['coal', 'wind', 'love']

    powers.each do |p|
      create(:json_resource, {:title => p})
    end

    resources = JSONModel(:resource).all(:page => 1)['results']
    resources.any? { |res| res.title == generate(:generic_title) }.should == false

    powers.each do |p|
      resources.any? { |res| res.title == p }.should == true
    end
  end

  it "lets you create a resource with an extent" do

    opts = {:portion => generate(:portion)}

    extents = [build(:json_extent, opts)]

    resource = create(:json_resource, :extents => extents)

    JSONModel(:resource).find(resource.id).extents.length.should eq(1)
    JSONModel(:resource).find(resource.id).extents[0]["portion"].should eq(opts[:portion])
  end


  it "lets you create a resource with an instance and container" do
    instance = build(:json_instance)

    id = create(:json_resource, :instances => [instance]).id

    JSONModel(:resource).find(id).instances.length.should eq(1)
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq(instance[:instance_type])
    JSONModel(:resource).find(id).instances[0]["sub_container"]["type_2"].should eq(instance[:sub_container]['type_2'])
  end


  it "lets you create a resource with an instance linked to a digital object" do
    digital_object = create(:json_digital_object)

    opts = {:instance_type => "digital_object",
            :digital_object => {:ref => digital_object.uri}
    }

    id = create(:json_resource,
                :instances => [build(:json_instance, opts)]
    ).id

    resource = JSONModel(:resource).find(id)
    resource.instances.length.should eq(1)
    resource.instances[0]["instance_type"].should eq(opts[:instance_type])
    resource.instances[0]["digital_object"]["ref"].should eq(opts[:digital_object][:ref])

    digital_object = JSONModel(:digital_object).find(digital_object.id)
    digital_object.linked_instances[0]["ref"].should eq(resource.uri)
  end


  it "lets you edit an instance of a resource" do
    instance = build(:json_instance)

    id = create(:json_resource, :instances => [instance]).id

    resource = JSONModel(:resource).find(id)

    new_instance_type = instance[:instance_type]
    new_instance_type = generate(:instance_type) until new_instance_type != instance[:instance_type]

    resource.instances[0]["instance_type"] = new_instance_type

    resource.save

    JSONModel(:resource).find(id).instances[0]["instance_type"].should_not eq(instance[:instance_type])
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq(new_instance_type)
  end

  it "lets you create a resource with an instance with a container with a location (and the location is resolved)" do

    # create the resource with all the instance/container etc
    location = create(:json_location, :temporary => generate(:temporary_location_type))
    status = 'current'

    top_container = create(:json_top_container,
                           :container_locations => [{'ref' => location.uri,
                                                      'status' => status,
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}])

    resource = create(:json_resource, {
                        :instances => [build(:json_instance,
                          :sub_container => build(:json_sub_container,
                                                  :top_container => {:ref => top_container.uri}))]})

    obj = JSONModel(:resource).find(resource.id, "resolve[]" => "top_container::container_locations")

    container_location = obj.instances[0]["sub_container"]['top_container']['_resolved']["container_locations"][0]

    container_location["status"].should eq(status)
    container_location["_resolved"]["building"].should eq(location.building)
  end


  it "correctly substitutes the repo_id in nested URIs" do

    accession = create(:json_accession)

    resource = create(:json_resource, {
                        :extents => [build(:json_extent)],
                        :related_accessions => [{
                          :ref => "/repositories/#{$repo_id}/accessions/#{accession.id}"
                        }]
    })

    # Set our default repository to nil here since we're really testing the fact
    # that the :repo_id parameter is passed through faithfully, and the global
    # setting would otherwise mask the error.
    #
    JSONModel.with_repository(nil) do
      accession_ref = JSONModel(:resource).find(resource.id, :repo_id => $repo_id)["related_accessions"][0]
      accession_ref["ref"].should eq("/repositories/#{$repo_id}/accessions/#{accession.id}")
    end
  end


  it "supports resolving subjects" do

    test_subject_term = generate(:term)

    vocab = create(:json_vocab)

    subject = create(:json_subject, {
                        :terms => [build(:json_term, {
                          :term => test_subject_term,
                          :vocabulary => vocab.uri
                        })],
                        :vocabulary => vocab.uri
    })

    r = create(:json_resource, {
                 :subjects => [{:ref => subject.uri}]
               })

    resource = JSONModel(:resource).find(r.id, "resolve[]" => ["subjects"])

    # yowza!
    resource["subjects"][0]["_resolved"]["terms"][0]["term"].should eq(test_subject_term)
  end


  it "allows an resource to be created with an attached deaccession" do

    test_begin_date = generate(:yyyy_mm_dd)
    test_boolean = (rand(2) == 1) ? false : true

    r = create(:json_resource,
               :deaccessions => [build(:json_deaccession, {
                 :scope => "whole",
                 :date => build(:json_date, {
                   :begin => test_begin_date
                 })
               })]
               )

    JSONModel(:resource).find(r.id).deaccessions.length.should eq(1)
    JSONModel(:resource).find(r.id).deaccessions[0]["scope"].should eq("whole")
    JSONModel(:resource).find(r.id).deaccessions[0]["date"]["begin"].should eq(test_begin_date)
  end


  it "allows a resource to have multiple direct children" do
    resource = create(:json_resource)

    ao1 = build(:json_archival_object)
    ao2 = build(:json_archival_object)

    ao1.resource = {:ref => resource.uri}
    ao2.resource = {:ref => resource.uri}

    ao1.save
    ao2.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)
    tree.children.length.should eq(2)
  end


  it "doesn't mix up resources and archival objects when attaching extents" do
    resource = create(:json_resource)
    ao = create(:json_archival_object,
                :resource => {:ref => resource.uri})

    ao.extents = [build(:json_extent)]
    ao.save

    resource = JSONModel(:resource).find(resource.id)

    # Adding the extent to the archival object shouldn't affect the resource's extents.
    resource.extents.length.should eq(1)
  end



  it "can store some notes and get them back" do
    resource = create(:json_resource)

    notes = build(:json_note_bibliography, :persistent_id => "something")
    index = build(:json_note_index, :persistent_id => "else")

    resource.notes = [notes, index]
    resource.save

    JSONModel(:resource).find(resource.id)[:notes].first['content'].should eq(notes.to_hash['content'])
    JSONModel(:resource).find(resource.id)[:notes].last['content'].should eq(index.to_hash['content'])
  end


  it "automatically generates persistent IDs for notes if not given" do
    resource = create(:json_resource)

    notes = build(:json_note_bibliography)
    resource.notes = [notes]
    resource.save

    JSONModel(:resource).find(resource.id)[:notes].first['persistent_id'].should_not be(nil)
  end


  it "doesn't allow you to link to a URI outside of the current repo" do
    resource = create(:json_resource)
    accession = create(:json_accession)

    # Rubbish!
    resource.related_accessions = [{'ref' => "/repositories/99999/accessions/#{accession.id}"}]

    expect {
      resource.save
    }.to raise_error(JSONModel::ValidationException)
  end


  it "retains order of linked agents" do

    agent_a = create(:json_agent_person)
    agent_b = create(:json_agent_family)

    resource = create(:json_resource, :linked_agents => [
                                                         {:ref => agent_a.uri, :role => 'creator'},
                                                         {:ref => agent_b.uri, :role => 'creator'},
                                                        ])

    JSONModel(:resource).find(resource.id).linked_agents[0]['ref'].should eq(agent_a.uri)
    JSONModel(:resource).find(resource.id).linked_agents[1]['ref'].should eq(agent_b.uri)

    agent_c = create(:json_agent_corporate_entity)

    resource.linked_agents = [
      {:ref => agent_c.uri, :role => 'creator'},
      {:ref => agent_b.uri, :role => 'creator'},
      {:ref => agent_a.uri, :role => 'creator'},
    ]
    resource.save

    JSONModel(:resource).find(resource.id).linked_agents[0]['ref'].should eq(agent_c.uri)
    JSONModel(:resource).find(resource.id).linked_agents[1]['ref'].should eq(agent_b.uri)
    JSONModel(:resource).find(resource.id).linked_agents[2]['ref'].should eq(agent_a.uri)
  end


  it "supports a title property on linked agents" do

    agent_a = create(:json_agent_person)

    resource = create(:json_resource, :linked_agents => [
                                                         {
                                                           :ref => agent_a.uri,
                                                           :role => 'creator',
                                                           :title => 'the title'
                                                         }
                                                        ])

    JSONModel(:resource).find(resource.id).linked_agents[0]['title'].should eq('the title')
  end


  it "publishes the resource, subrecords and components when /publish is POSTed" do
    resource = create(:json_resource, {
      :publish => false,
      :external_documents => [build(:json_external_document, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})]
    })


    vocab = create(:json_vocab)
    vocab_uri = JSONModel(:vocabulary).uri_for(vocab.id)

    subject = create(:json_subject,
                     :terms => [build(:json_term, :vocabulary => vocab_uri)],
                     :vocabulary => vocab_uri)


    archival_object = create(:json_archival_object, {
      :publish => false,
      :resource => {:ref => resource.uri},
      :external_documents => [build(:json_external_document, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})],
      :subjects => [{:ref => subject.uri}]
    })

    url = URI("#{JSONModel::HTTP.backend_url}#{resource.uri}/publish")

    request = Net::HTTP::Post.new(url.request_uri)
    response = JSONModel::HTTP.do_http_request(url, request)


    resource = JSONModel(:resource).find(resource.id)
    resource.publish.should eq(true)
    resource.external_documents[0]["publish"].should eq(true)
    resource.notes[0]["publish"].should eq(true)

    archival_object = JSONModel(:archival_object).find(archival_object.id)
    archival_object.publish.should eq(true)
    archival_object.external_documents[0]["publish"].should eq(true)
    archival_object.notes[0]["publish"].should eq(true)
  end


  it "allows posting of array of children" do
    resource = create(:json_resource)

    archival_object_1 = build(:json_archival_object)
    archival_object_2 = build(:json_archival_object)

    children = JSONModel(:archival_record_children).from_hash({
                                                                "children" => [archival_object_1, archival_object_2]
                                                              })

    url = URI("#{JSONModel::HTTP.backend_url}#{resource.uri}/children")
    response = JSONModel::HTTP.post_json(url, children.to_json)
    json_response = ASUtils.json_parse(response.body)

    json_response["status"].should eq("Updated")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)
    tree.children.length.should eq(2)

    tree.children[0]["title"].should eq(archival_object_1["title"])
    tree.children[1]["title"].should eq(archival_object_2["title"])
  end


  it "accepts move of multiple children" do
    resource = create(:json_resource)
    ao = create(:json_archival_object, :resource => {:ref => resource.uri})

    child_1 = create(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => ao.uri})
    child_2 = create(:json_archival_object, :resource => {:ref => resource.uri}, :parent => {:ref => ao.uri})

    response = JSONModel::HTTP::post_form("#{resource.uri}/accept_children", {"children[]" => [child_1.uri, child_2.uri], "position" => 0})
    json_response = ASUtils.json_parse(response.body)

    json_response["status"].should eq("Updated")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.children.length.should eq(3)
    tree.children[0]["title"].should eq(child_1["title"])
    tree.children[0]["record_uri"].should eq(child_1.uri)

    tree.children[1]["title"].should eq(child_2["title"])
    tree.children[1]["record_uri"].should eq(child_2.uri)

    tree.children[2]["title"].should eq(ao["title"])
    tree.children[2]["record_uri"].should eq(ao.uri)
  end


  it "can resolve a link in an index note" do
    resource = create(:json_resource)
    resource.save
    linked_archival_object = create(:json_archival_object, :resource => {:ref => resource.uri})
    linked_archival_object.save
    ref_id = linked_archival_object.ref_id
    linked_uri = linked_archival_object.uri

    archival_object = create(:json_archival_object, :resource => {:ref => resource.uri})

    notes = build(:json_note_index, 'items' => [build(:json_note_index_item, 'reference' => ref_id)])

    archival_object.notes = [notes]
    archival_object.save

    ao = JSONModel(:archival_object).find(archival_object.id)
    ao[:notes].first['items'].first['reference_ref']['ref'].should eq(linked_uri)
  end


  it "can list the record types in the object's graph" do
    extents = [build(:json_extent)]

    resource = create(:json_resource, :extents => extents)
    uri = JSONModel(:resource).uri_for(resource.id) + "/models_in_graph"

    list = JSONModel::HTTP.get_json(uri)
    list.should include('extent');
    list.should_not include('subject');

  end

end
