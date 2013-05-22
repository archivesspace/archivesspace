require 'spec_helper'

describe 'Resources controller' do

  before(:each) do
    create(:repo)
  end


  it "lets you create a resource and get it back" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "level" => "collection", "language" => "eng", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
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
    }.to raise_error
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
    resources.any? { |res| res.title == generate(:generic_title) }.should be_false

    powers.each do |p|
      resources.any? { |res| res.title == p }.should be_true
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
    
    opts = {:instance_type => generate(:instance_type),
            :container => build(:json_container)
            }
    
    id = create(:json_resource, 
                :instances => [build(:json_instance, opts)]
                ).id

    JSONModel(:resource).find(id).instances.length.should eq(1)
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq(opts[:instance_type])
    JSONModel(:resource).find(id).instances[0]["container"]["type_1"].should eq(opts[:container]['type_1'])
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
    
    opts = {:instance_type => generate(:instance_type),
            :container => build(:json_container)
            }
            
    id = create(:json_resource, 
                :instances => [build(:json_instance, opts)]
                ).id

    resource = JSONModel(:resource).find(id)

    old_type = opts[:instance_type]
    until old_type != opts[:instance_type]
      opts[:instance_type] = generate(:instance_type)
    end
    
    resource.instances[0]["instance_type"] = opts[:instance_type]

    resource.save

    JSONModel(:resource).find(id).instances[0]["instance_type"].should_not eq(old_type)
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq(opts[:instance_type])
  end

  it "lets you create a resource with an instance with a container with a location (and the location is resolved)" do

    # create the resource with all the instance/container etc
    location = create(:json_location, :temporary => generate(:temporary_location_type))
    status = 'current'

    resource = create(:json_resource, {
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [{'ref' => location.uri,
                                                      'status' => status,
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}]
                            })
                        })]
                      })

    obj = JSONModel(:resource).find(resource.id, "resolve[]" => "container_locations")

    obj.instances[0]["container"]["container_locations"][0]["status"].should eq(status)
    obj.instances[0]["container"]["container_locations"][0]["_resolved"]["building"].should eq(location.building)
  end


  it "lets you create a resource with an instance/container/location, and then update the location" do
    location = create(:json_location, :temporary => generate(:temporary_location_type))

    resource = create(:json_resource, {
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [{'ref' => location.uri,
                                                      'status' => 'current',
                                                      'start_date' => generate(:yyyy_mm_dd),
                                                      'end_date' => generate(:yyyy_mm_dd)}]
                            })
                        })]
                      })

    obj = JSONModel(:resource).find(resource.id)

    obj['instances'][0]['container']['container_locations'][0]['status'] = 'current'
    obj.save
  end


  it "does not permit a resource's instance's container to be linked to a location with a status of 'previous' unless the location is designated 'temporary'" do

    # create a location
    location_one = create(:json_location, :temporary => nil)
    location_two = create(:json_location, :temporary => generate(:temporary_location_type))
    # create the resource with all the instance/container etc

    l = lambda { |location|
      resource = create(:json_resource, {
                          :instances => [build(:json_instance, {
                            :container => build(:json_container, {
                              :container_locations => [{
                                 'ref' => location.uri,
                                 'status' => 'previous',
                                 'start_date' => generate(:yyyy_mm_dd),
                                 'end_date' => generate(:yyyy_mm_dd)
                               }]
                            })
                          })]
                        })

    }

    expect{ l.call(location_one) }.to raise_error
    expect{ l.call(location_two) }.to_not raise_error

    err = nil
    begin
      l.call(location_one)
    rescue
      err = $!
    end

    err.should be_an_instance_of(ValidationException)
    err.errors.keys.should eq(["instances/0/container/container_locations/0/status"])
  end


  it "allows a resource's instance's container to be linked to a temporary location when the status is 'previous'" do
    # create a location
    temp = generate(:temporary_location_type)
    status = 'previous'

    location = create(:json_location,
                      :temporary => temp)

    resource = create(:json_resource, {
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [{
                              'status' => status,
                              'start_date' => generate(:yyyy_mm_dd),
                              'end_date' => generate(:yyyy_mm_dd),
                              'ref' => location.uri
                            }]
                          })
                        })]
    })

      id = resource.id
      obj = JSONModel(:resource).find(id, "resolve[]" => "container_locations")

      obj.instances[0]["container"]["container_locations"][0]["status"].should eq(status)
      obj.instances[0]["container"]["container_locations"][0]["_resolved"]["temporary"].should eq(temp)
  end


  it "correctly substitutes the repo_id in nested URIs" do

    location = create(:json_location)

    resource = create(:json_resource, {
                        :extents => [build(:json_extent)],
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [{
                              :start_date => generate(:yyyy_mm_dd),
                              :end_date => generate(:yyyy_mm_dd),
                              :status => 'current',
                              :ref => "/repositories/#{$repo_id}/locations/#{location.id}"
                            }]
                          })
                        })]
    })

    # Set our default repository to nil here since we're really testing the fact
    # that the :repo_id parameter is passed through faithfully, and the global
    # setting would otherwise mask the error.
    #
    JSONModel.with_repository(nil) do
      container_location = JSONModel(:resource).find(resource.id, :repo_id => $repo_id)["instances"][0]["container"]["container_locations"][0]
      container_location["ref"].should eq("/repositories/#{$repo_id}/locations/#{location.id}")
    end
  end


  # it "reports an error when marking a non-temporary location as 'previous'" do
  # merged this test into:
  #  'does not permit a resource's instance's container to be linked to a location with a status of 'previous'...'


  it "supports resolving locations and subjects" do

    test_barcode = generate(:barcode)
    test_subject_term = generate(:term)

    vocab = create(:json_vocab)

    subject = create(:json_subject, {
                        :terms => [build(:json_term, {
                          :term => test_subject_term,
                          :vocabulary => vocab.uri
                        })],
                        :vocabulary => vocab.uri
    })

    location = create(:json_location, {
                        :barcode => test_barcode
    })


    r = create(:json_resource, {
                 :subjects => [{:ref => subject.uri}],
                 :instances => [build(:json_instance, {
                                        :container => build(:json_container, {
                                                              :container_locations => [{:ref => location.uri,
                                                                                        :status => "current",
                                                                                        :start_date => generate(:yyyy_mm_dd),
                                                                                        :end_date => generate(:yyyy_mm_dd),
                                                                                        :location => location.uri}]
                                                            })
                                      })]
               })

    resource = JSONModel(:resource).find(r.id, "resolve[]" => ["subjects", "container_locations"])

    # yowza!
    resource["instances"][0]["container"]["container_locations"][0]["_resolved"]["barcode"].should eq(test_barcode)
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

    notes = build(:json_note_bibliography)

    # No 'content' but that's OK because it's optional for notes of type index.
    index = JSONModel(:note_index).from_hash(:items => [{
                                                          :value => 'something',
                                                          :type => 'else'
                                                        }])

    resource.notes = [notes, index]
    resource.save

    JSONModel(:resource).find(resource.id)[:notes].first.should eq(notes.to_hash)
  end


  it "doesn't allow you to link to a URI outside of the current repo" do
    resource = create(:json_resource)
    accession = create(:json_accession)

    # Rubbish!
    resource.related_accessions = [{'ref' => "/repositories/99999/accessions/#{accession.id}"}]

    expect {
      resource.save
    }.to raise_error(StandardError, /Invalid URI reference/)
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


  it "publishes the resource, subrecords and components when /publish is POSTed" do
    resource = create(:json_resource, {
      :publish => false,
      :external_documents => [build(:json_external_document, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})]
    })

    archival_object = create(:json_archival_object, {
      :publish => false,
      :resource => {:ref => resource.uri},
      :external_documents => [build(:json_external_document, {:publish => false})],
      :notes => [build(:json_note_bibliography, {:publish => false})]
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

end
