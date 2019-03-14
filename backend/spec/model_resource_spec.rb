require 'spec_helper'

describe 'Resource model' do

  it "allows resources to be created" do
    opts = {:title => generate(:generic_title)}

    resource = create_resource(opts)

    expect(Resource[resource[:id]].title).to eq(opts[:title])
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
    }.not_to raise_error
  end


  it "allows resources to be created with a date" do
    opts = {:dates => [build(:json_date)]}

    resource = create_resource(opts)

    expect(Resource[resource[:id]].date.length).to eq(1)
    expect(Resource[resource[:id]].date[0].begin).to eq(opts[:dates][0]['begin'])
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
    expect(res.instance.length).to eq(1)
    expect(res.instance[0].instance_type).to eq(opts[:instances][0]['instance_type'])

    res = URIResolver.resolve_references(Resource.to_jsonmodel(resource[:id]), ['top_container'])
    expect(res['instances'][0]["sub_container"]['top_container']['_resolved']["type"]).to eq(top["type"])
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
    }.not_to raise_error
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

    expect(resource.related_records(:classification).first.title).to eq("top-level classification")
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

    expect { resource.update_from_json(json) }.not_to raise_error
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

    expect(Resource.to_jsonmodel(resource.id).representative_image['file_uri']).to match(/bar3/)

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

    expect(Resource.to_jsonmodel(resource.id).representative_image).to be_falsey

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

    expect(Resource.to_jsonmodel(resource.id).representative_image).to be_falsey

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

    expect(Resource.to_jsonmodel(resource.id).representative_image['file_uri']).to match(/bar2/)

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

    expect(Resource.to_jsonmodel(resource.id).representative_image['file_uri']).to match(/bar2/)
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

  describe "slug tests" do
    describe "slug autogen enabled" do
      it "autogenerates a slug via title when configured to generate by title" do
        AppConfig[:auto_generate_slugs_with_id] = false 
        AppConfig[:generate_resource_slugs_with_eadid] = false

        json = build(:json_resource)
        resource = Resource.create_from_json(json)

        expected_slug = resource[:title].gsub(" ", "_")
                                        .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

        expect(resource[:slug]).to eq(expected_slug)
      end

      it "autogenerates a slug via identifier when configured to generate by id but not eadid" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = false
  
        json = build(:json_resource)
        resource = Resource.create_from_json(json)
        
        expected_slug = resource[:identifier].gsub("null", '')
                    .gsub!(/[\[\]]/,'')
                    .gsub(",", '')
                    .split('"')
                    .select {|s| !s.empty?}
                    .join("-")
  
        expect(resource[:slug]).to eq(expected_slug)
      end
    end
    
    describe "slug autogen disabled and then turned on" do
      it "autogenerates a slug via title when configured to generate by title" do
        AppConfig[:auto_generate_slugs_with_id] = false 
        AppConfig[:generate_resource_slugs_with_eadid] = false

        json = build(:json_resource, :is_slug_auto => false)
        resource = Resource.create_from_json(json)

        resource.update(:is_slug_auto => 1)

        expected_slug = resource[:title].gsub(" ", "_")
                                        .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

        expect(resource[:slug]).to eq(expected_slug)
      end

      it "autogenerates a slug via eadid when configured to generate by name and eadid" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = true
  
        json = build(:json_resource, {:ead_id => rand(1000000).to_s, :is_slug_auto => false})
  
        resource = Resource.create_from_json(json)
        resource.update(:is_slug_auto => 1)
  
        expected_slug = "_" + resource[:ead_id].gsub(" ", "_")
                                                   .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")
  
        expect(resource[:slug]).to eq(expected_slug)
      end

      it "autogenerates a slug via eadid when configured to generate by name and eadid, but eadid missing" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = true
  
        json = build(:json_resource, {:ead_id => nil, :is_slug_auto => false })
        resource = Resource.create_from_json(json)
        resource.update(:is_slug_auto => 1)
  
        expected_slug = resource[:identifier].gsub("null", '')
                    .gsub!(/[\[\]]/,'')
                    .gsub(",", '')
                    .split('"')
                    .select {|s| !s.empty?}
                    .join("-")
  
        expect(resource[:slug]).to eq(expected_slug)
      end

      it "autogenerates a slug via identifier when configured to generate by id but not eadid" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = false
  
        json = build(:json_resource, :is_slug_auto => false)
        resource = Resource.create_from_json(json)
        
        resource.update(:is_slug_auto => 1)
  
        expected_slug = resource[:identifier].gsub("null", '')
                    .gsub!(/[\[\]]/,'')
                    .gsub(",", '')
                    .split('"')
                    .select {|s| !s.empty?}
                    .join("-")
  
        expect(resource[:slug]).to eq(expected_slug)
      end
    end

    describe "slug code does not run" do
      it "does not execute slug code when auto-gen on id and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = false
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        resource.update(:title => "foobar")
      end

      it "does not execute slug code when auto-gen on eadid and title and identifier are changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = true
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        resource.update(:title => "foobar")
        resource.update(:id_0 => "barfoo")
      end
  
  
      it "does not execute slug code when auto-gen on title and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        resource.update(:id_0 => "foobar")
      end
  
      it "does not execute slug code when auto-gen off and title, identifier and eadid changed" do
        json = build(:json_resource, {:is_slug_auto => false, :slug => ""})
        resource = Resource.create_from_json(json)
  
        expect(resource).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)

        resource.update(:id_0 => "foobar")
        resource.update(:title => "barfoo")
        resource.update(:ead_id => "bazbim")
      end
    end

    describe "slug code runs" do
      it "executes slug code when auto-gen on id and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = false
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to receive(:auto_gen_slug!)
        expect(SlugHelpers).to receive(:clean_slug)
  
        resource.update(:id_0 => 'foo')
      end

      it "executes slug code when auto-gen on eadid and eadid is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
        AppConfig[:generate_resource_slugs_with_eadid] = true
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to receive(:auto_gen_slug!)
  
        resource.update(:ead_id => "foobar")
      end

      it "executes slug code when auto-gen on title and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false
  
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => true}))
  
        expect(resource).to receive(:auto_gen_slug!)
  
        resource.update(:title => "foobar")
      end

      it "executes slug code when autogen is turned on" do
        AppConfig[:auto_generate_slugs_with_id] = false
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => false}))
  
        expect(resource).to receive(:auto_gen_slug!)
  
        resource.update(:is_slug_auto => 1)
      end

      it "executes slug code when autogen is off and slug is updated" do
        resource = Resource.create_from_json(build(:json_resource, {:is_slug_auto => false}))
  
        expect(SlugHelpers).to receive(:clean_slug)
  
        resource.update(:slug => "snow white")
      end
    end
  end
end
