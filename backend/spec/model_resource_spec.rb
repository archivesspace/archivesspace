require 'spec_helper'

describe 'Resource model' do

  it "allows resources to be created" do
    opts = {:title => generate(:generic_title)}

    resource = create_resource(opts)

    Resource[resource[:id]].title.should eq(opts[:title])
  end


  it "prevents duplicate IDs " do
    opts = {:id_0 => generate(:alphanumstr)}

    create_resource(opts)

    expect { create_resource(opts) }.to raise_error(Sequel::ValidationFailed)
  end


  it "reports an error if id_0 has no value" do
    opts = {:id_0 => nil}

    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "doesn't enforce ID uniqueness between repositories" do
    repo1 = make_test_repo("REPO1")
    repo2 = make_test_repo("REPO2")

    expect {
      [repo1, repo2].each do |repo_id|
        Resource.create_from_json(build(:json_resource,
                                         {
                                           :id_0 => "1234",
                                           :id_1 => "5678",
                                           :id_2 => "9876",
                                           :id_3 => "5432"
                                         }),
                                   :repo_id => repo_id)
      end
    }.to_not raise_error
  end


  it "allows resources to be created with a date" do
    opts = {:dates => [build(:json_date)]}

    resource = create_resource(opts)

    Resource[resource[:id]].date.length.should eq(1)
    Resource[resource[:id]].date[0].begin.should eq(opts[:dates][0]['begin'])
  end


  it "throws an exception if extents is nil" do
    expect { create_resource({:extents => nil}) }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an exception if extents is empty" do
    expect { create_resource({:extents => []}) }.to raise_error(JSONModel::ValidationException)
  end


  it "blows up if you don't specify which repository you're querying" do
    resource = create_resource

    expect {
      RequestContext.put(:repo_id, nil)
      Resource.to_jsonmodel(resource[:id])
    }.to raise_error(RuntimeError)
  end


  it "can be created with an instance" do
    top = create(:json_top_container)
    opts = {:instances => [build(:json_instance,
                                 :sub_container => build(:json_sub_container,
                                                         :top_container => {:ref => top.uri}))]}
    resource = create_resource(opts)
    res = Resource[resource[:id]]
    res.instance.length.should eq(1)
    res.instance[0].instance_type.should eq(opts[:instances][0]['instance_type'])

    res = URIResolver.resolve_references(Resource.to_jsonmodel(resource[:id]), ['top_container'])
    res['instances'][0]["sub_container"]['top_container']['_resolved']["type"].should eq(top["type"])
  end


  it "throws an error when no language is provided" do
    opts = {:language => nil}

    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "throws an error if 'level' is 'otherlevel' and 'other level' isn't provided" do
    opts = {:level => "otherlevel", :other_level => nil}

    expect { create_resource(opts) }.to raise_error(JSONModel::ValidationException)
  end


  it "allows long titles" do
    expect {
      res = create(:resource, {:repo_id => $repo_id, :title => 200.times.map { 'moo'}.join})
    }.to_not raise_error
  end


  it "ensures that ead_ids are unique" do
    create_resource(:ead_id => "hello")

    expect {
      create_resource(:ead_id => "hello")
    }.to raise_error(Sequel::ValidationFailed)
  end


  it "can be linked to a classification" do
    classification = build(:json_classification,
                           :title => "top-level classification",
                           :identifier => "abcdef",
                           :description => "A classification")

    classification = Classification.create_from_json(classification)
    resource = create_resource(:classifications =>[   {'ref' => classification.uri} ])

    resource.related_records(:classification).first.title.should eq("top-level classification")
  end

  # See https://gist.github.com/anarchivist/7477913
  it "can update records that have external ids" do
    opts = {
      :id_0 => "test",
      :id_1 => "4444",
      :ead_id => "test000",
      :finding_aid_title => "Test",
      :finding_aid_subtitle => "SubTest"
    }

    json = build(:json_resource, opts)

    json[:external_ids] =
      [{
         :source => "Archivists Toolkit Database::RESOURCE",
         :external_id => "1"
       }]

    resource = Resource.create_from_json(json, :repo_id => $repo_id)

    json[:lock_version] = 0

    expect { resource.update_from_json(json) }.to_not raise_error
  end

  it "defaults the representative image to the first 'image-service' file_version it is linked to through its instances" do
    uris = ["http://foo.com/bar1", "http://foo.com/bar2", "http://foo.com/bar3"]

    do1 = create(:json_digital_object, {
                   :publish => true,
                   :file_versions => [
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => uris.shift,
                                              :use_statement => 'audio-service'
                                            })]})

    do2 = create(:json_digital_object, {
                   :publish => true,
                   :file_versions => [
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => uris.shift,
                                              :use_statement => 'audio-service'
                                            }),
                                      build(:json_file_version, {
                                              :publish => true,
                                              :file_uri => uris.shift,
                                              :use_statement => 'image-service'
                                            })
                                     ]})



    resource = create_resource({
                               :instances => [build(:json_instance_digital, {
                                                      :digital_object => {'ref' => do1.uri}
                                                    }),
                                              build(:json_instance_digital, {
                                                      :digital_object => {'ref' => do2.uri}
                                                    })
                                             ]
                             })

    r = Resource.to_jsonmodel(resource.id)

    Resource.to_jsonmodel(resource.id).representative_image['file_uri'].should match(/bar3/)

  end


  it "won't use a file_instance from a non-published digital object as the representative image" do
    dobj = create(:json_digital_object, {
                    :publish => false,
                    :file_versions => [build(:json_file_version, {
                                               :publish => true,
                                               :file_uri => 'http://secret.cia.gov/puppetmaster.jpg',
                                               :use_statement => 'image-service'
                                            })
                                     ]})


    resource = create_resource({
                                 :instances => [build(:json_instance_digital, {
                                                        :digital_object => {'ref' => dobj.uri}
                                                      })]
                               })

    r = Resource.to_jsonmodel(resource.id)

    Resource.to_jsonmodel(resource.id).representative_image.should be_falsey

  end


  it "won't use a non-published file_instance from a published digital object as the representative image" do
    dobj = create(:json_digital_object, {
                    :publish => true,
                    :file_versions => [build(:json_file_version, {
                                               :publish => false,
                                               :file_uri => 'http://secret.cia.gov/puppetmaster.jpg',
                                               :use_statement => 'image-service'
                                            })
                                     ]})


    resource = create_resource({
                                 :instances => [build(:json_instance_digital, {
                                                        :digital_object => {'ref' => dobj.uri}
                                                      })]
                               })

    r = Resource.to_jsonmodel(resource.id)

    Resource.to_jsonmodel(resource.id).representative_image.should be_falsey

  end


  it "will use the instance flagged with 'is_representative'" do
    d1 = create(:json_digital_object, {
                  :publish => true,
                  :file_versions => [build(:json_file_version, {
                                             :publish => true,
                                             :is_representative => true,
                                             :file_uri => 'http://foo.com/bar1',
                                             :use_statement => 'image-service'
                                            })
                                     ]})

    d2 = create(:json_digital_object, {
                  :publish => true,
                  :file_versions => [build(:json_file_version, {
                                             :publish => true,
                                             :file_uri => 'http://foo.com/bar2',
                                             :use_statement => 'image-service'
                                            })
                                     ]})



    resource = create_resource({
                                 :instances => [build(:json_instance_digital, {
                                                        :digital_object => {'ref' => d1.uri}
                                                      }),
                                                build(:json_instance_digital, {
                                                        :is_representative => true,
                                                        :digital_object => {'ref' => d2.uri}
                                                      })]
                               })

    r = Resource.to_jsonmodel(resource.id)

    Resource.to_jsonmodel(resource.id).representative_image['file_uri'].should match(/bar2/)

  end


  it "will use the file_version flagged with 'is_representative'" do
    d1 = create(:json_digital_object, {
                  :publish => true,
                  :file_versions => [build(:json_file_version, {
                                             :publish => true,
                                             :file_uri => 'http://foo.com/bar1',
                                             :use_statement => 'image-service'
                                            }),
                                     build(:json_file_version, {
                                             :publish => true,
                                             :is_representative => true,
                                             :file_uri => 'http://foo.com/bar2',
                                             :use_statement => 'image-service'
                                           })

                                     ]})

    resource = create_resource({
                                 :instances => [build(:json_instance_digital, {
                                                        :digital_object => {'ref' => d1.uri}
                                                      })]
                               })

    r = Resource.to_jsonmodel(resource.id)

    Resource.to_jsonmodel(resource.id).representative_image['file_uri'].should match(/bar2/)
  end


  it "won't allow more than one intance flagged 'is_representative'" do
    d1 = create(:json_digital_object, {
                  :publish => true,
                  :file_versions => [build(:json_file_version, {
                                             :publish => true,
                                             :file_uri => 'http://foo.com/bar1',
                                             :use_statement => 'image-service'
                                            })
                                     ]})

    d2 = create(:json_digital_object, {
                  :publish => true,
                  :file_versions => [build(:json_file_version, {
                                             :publish => true,
                                             :file_uri => 'http://foo.com/bar2',
                                             :use_statement => 'image-service'
                                            })
                                     ]})

    json = build(:json_resource, {
                   :instances => [build(:json_instance_digital, {
                                          :is_representative => true,
                                          :digital_object => {'ref' => d1.uri}
                                        }),
                                  build(:json_instance_digital, {
                                          :is_representative => true,
                                          :digital_object => {'ref' => d1.uri}
                                        })
]
                 })


    expect {
      Resource.create_from_json(json)

    }.to raise_error(Sequel::ValidationFailed)


  end


end
