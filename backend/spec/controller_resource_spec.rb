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


  it "lets you created resources with no 4-part identifiers" do
    create(:json_resource,
           :id_0 => nil, :id_1 => nil, :id_2 => nil, :id_3 => nil)

    create(:json_resource,
           :id_0 => nil, :id_1 => nil, :id_2 => nil, :id_3 => nil)
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
        ao.parent = aos.last.uri
      end

      ao.resource = resource.uri

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
                    :terms => [build(:json_term, :vocabulary => vocab_uri).to_hash],
                    :vocabulary => vocab_uri
                    )

    resource = create(:json_resource, :subjects => [subject.uri])

    JSONModel(:resource).find(resource.id).subjects[0].should eq(subject.uri)
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
    
    extents = [build(:json_extent, opts).to_hash]
    
    resource = create(:json_resource, :extents => extents)

    JSONModel(:resource).find(resource.id).extents.length.should eq(1)
    JSONModel(:resource).find(resource.id).extents[0]["portion"].should eq(opts[:portion])
  end


  it "lets you create a resource with an instance and container" do
    
    opts = {:instance_type => generate(:instance_type),
            :container => build(:json_container).to_hash
            }
    
    id = create(:json_resource, 
                :instances => [build(:json_instance, opts).to_hash]
                ).id

    JSONModel(:resource).find(id).instances.length.should eq(1)
    JSONModel(:resource).find(id).instances[0]["instance_type"].should eq(opts[:instance_type])
    JSONModel(:resource).find(id).instances[0]["container"]["type_1"].should eq(opts[:container]['type_1'])
  end


  it "lets you edit an instance of a resource" do
    
    opts = {:instance_type => generate(:instance_type),
            :container => build(:json_container).to_hash
            }
            
    id = create(:json_resource, 
                :instances => [build(:json_instance, opts).to_hash]
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
    status = generate(:container_location_status)
    
    resource = create(:json_resource, {
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [build(:json_container_location, {
                              :location => location.uri,
                              :status => status
                              }).to_hash]
                            }).to_hash
                        }).to_hash]
                      })
                                                                    

    JSONModel(:resource).find(resource.id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["status"].should eq(status)
    JSONModel(:resource).find(resource.id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["resolved"]["location"]["building"].should eq(location.building)
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
                              :container_locations => [build(:json_container_location, {
                                 :status => 'previous',
                                 :location => location.uri
                               }).to_hash]
                            }).to_hash
                          }).to_hash]
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
    
    location = build(:json_location, 
                      :temporary => 'loan')

    resource = create(:json_resource, {
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [build(:json_container_location, {
                              :status => status,
                              :location => build(:json_location, {
                                :temporary => temp
                              }).to_hash
                            }).to_hash]
                          }).to_hash
                        }).to_hash]
      
    })

      id = resource.id

      JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["status"].should eq(status)
      JSONModel(:resource).find(id, "resolve[]" => "location").instances[0]["container"]["container_locations"][0]["resolved"]["location"]["temporary"].should eq(temp)
  end


  it "correctly substitutes the repo_id in nested URIs" do

    location = create(:json_location)

    resource = create(:json_resource, {
                        :extents => [build(:json_extent).to_hash],
                        :instances => [build(:json_instance, {
                          :container => build(:json_container, {
                            :container_locations => [build(:json_container_location, {
                              :start_date => generate(:yyyy_mm_dd),
                              :end_date => generate(:yyyy_mm_dd),
                              :location => "/repositories/#{$repo_id}/locations/#{location.id}"
                            }).to_hash]
                          }).to_hash
                        }).to_hash]
    })

    # Set our default repository to nil here since we're really testing the fact
    # that the :repo_id parameter is passed through faithfully, and the global
    # setting would otherwise mask the error.
    #
    JSONModel.with_repository(nil) do
      container_location = JSONModel(:resource).find(resource.id, :repo_id => $repo_id)["instances"][0]["container"]["container_locations"][0]
      container_location["location"].should eq("/repositories/#{$repo_id}/locations/#{location.id}")
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
                        }).to_hash],
                        :vocabulary => vocab.uri
    })
    
    location = create(:json_location, {
                        :barcode => test_barcode
    })


    r = create(:json_resource, {
          :subjects => [subject.uri],
          :instances => [build(:json_instance, {
            :container => build(:json_container, {
              :container_locations => [build(:json_container_location, {
                :start_date => generate(:yyyy_mm_dd),
                :end_date => generate(:yyyy_mm_dd),
                :location => location.uri
              }).to_hash]
            }).to_hash
          }).to_hash]
    })

    resource = JSONModel(:resource).find(r.id, "resolve[]" => ["subjects", "location"])

    # yowza!
    resource["instances"][0]["container"]["container_locations"][0]["resolved"]["location"]["barcode"].should eq(test_barcode)
    resource["resolved"]["subjects"][0]["terms"][0]["term"].should eq(test_subject_term)
  end


  it "allows an resource to be created with an attached deaccession" do
    
    test_begin_date = generate(:yyyy_mm_dd)
    test_boolean = (rand(2) == 1) ? false : true
    
    r = create(:json_resource, 
               :deaccessions => [build(:json_deaccession, {
                 :whole_part => test_boolean,
                 :date => build(:json_date, {
                   :begin => test_begin_date
                 }).to_hash
               }).to_hash]
               )
    
    JSONModel(:resource).find(r.id).deaccessions.length.should eq(1)
    JSONModel(:resource).find(r.id).deaccessions[0]["whole_part"].should eq(test_boolean)
    JSONModel(:resource).find(r.id).deaccessions[0]["date"]["begin"].should eq(test_begin_date)
  end


  it "allows a resource to have multiple direct children" do
    resource = create(:json_resource)

    ao1 = build(:json_archival_object)
    ao2 = build(:json_archival_object)

    ao1.resource = resource.uri
    ao2.resource = resource.uri

    ao1.save
    ao2.save

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)
    tree.children.length.should eq(2)
  end


  it "doesn't mix up resources and archival objects when attaching extents" do
    resource = create(:json_resource)
    ao = create(:json_archival_object,
                :resource => resource.uri)

    ao.extents = [build(:json_extent).to_hash]
    ao.save

    resource = JSONModel(:resource).find(resource.id)

    # Adding the extent to the archival object shouldn't affect the resource's extents.
    resource.extents.length.should eq(1)
  end



  it "can store some notes and get them back" do
    resource = create(:json_resource)

    notes = build(:json_note_bibliography)

    resource.notes = [notes.to_hash]
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

end
