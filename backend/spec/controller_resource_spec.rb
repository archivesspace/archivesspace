require 'spec_helper'

describe 'Resources controller' do

  before(:each) do
    create(:repo)
  end
  
  # invert a non-branching resource tree
  def invert_tree(old_tree, new_tree = nil)
    if new_tree == nil
      new_tree = old_tree.clone
      new_tree['children'] = []
      old_tree = old_tree['children'][0] ||= nil
      invert_tree(old_tree, new_tree)
    elsif old_tree
      new_tree = old_tree.merge('children' => [new_tree])
      old_tree = old_tree['children'][0] ||= nil
      invert_tree(old_tree, new_tree)
    else
      new_tree
    end
  end
      

  it "lets you create a resource and get it back" do
    resource = JSONModel(:resource).from_hash("title" => "a resource", "id_0" => "abc123", "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}])
    id = resource.save

    JSONModel(:resource).find(id).title.should eq("a resource")
  end


  it "lets you manipulate the record hierarchy by rearranging the resource tree" do

    resource = create(:json_resource)
    id = resource.id

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = create(:json_archival_object, {:ref_id => name,
                                          :title => "archival object: #{name}"})
      if not aos.empty?
        ao.parent = aos.last.uri
      end

      ao.resource = resource.uri
      ao.save
      aos << ao
    end

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id).to_hash
    
    tree['archival_object'].should eq(aos[0].uri)
    tree['children'][0]['archival_object'].should eq(aos[1].uri)
    tree['children'][0]['children'][0]['archival_object'].should eq(aos[2].uri)


    # Now turn it on its head

    changed = invert_tree(tree)
    
    JSONModel(:resource_tree).from_hash(changed).save(:resource_id => resource.id)
    changed.delete("uri")

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree['archival_object'].should eq(aos[2].uri)
    tree['children'][0]['archival_object'].should eq(aos[1].uri)
    tree['children'][0]['children'][0]['archival_object'].should eq(aos[0].uri)

    tree.to_hash.should eq(changed)
  end



  it "lets you update a resource" do
    resource = create(:json_resource)

    resource.title = "an updated resource"
    resource.save

    JSONModel(:resource).find(resource.id).title.should eq("an updated resource")
  end


  it "can handle asking for the tree of an empty resource" do
    resource = create(:json_resource)

    tree = JSONModel(:resource_tree).find(nil, :resource_id => resource.id)

    tree.should eq(nil)
  end


  it "adds an archival object to a resource when it's added to the tree" do
    ao = create(:json_archival_object)

    resource = create(:json_resource)

    tree = JSONModel(:resource_tree).from_hash(:archival_object => ao.uri,
                                               :children => [])

    tree.save(:resource_id => resource.id)

    JSONModel(:archival_object).find(ao.id).resource == "#{$repo}/resources/#{resource.id}"
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

    resources = JSONModel(:resource).all
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

end
