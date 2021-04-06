require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Resource model' do

  it "allows resources to be created" do
    opts = {:title => generate(:generic_title)}

    resource = create_resource(opts)

    expect(Resource[resource[:id]].title).to eq(opts[:title])
    resource.delete
  end

  it "creates an ARK name with resource" do
    AppConfig[:arks_enabled] = true
    opts = {:title => generate(:generic_title)}
    resource = create_resource(opts)
    expect(ArkName.first(:resource_id => resource.id)).to_not be_nil
    resource.delete
    AppConfig[:arks_enabled] = false
  end

  it "deletes ARK Name when resource is deleted" do
    AppConfig[:arks_enabled] = true
    opts = {:title => generate(:generic_title)}
    resource = create_resource(opts)
    resource_id = resource.id
    expect(ArkName.first(:resource_id => resource_id)).to_not be_nil
    resource.delete
    expect(ArkName.first(:resource_id => resource_id)).to be_nil
    AppConfig[:arks_enabled] = false
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
    opts = {:lang_materials => [{"language_and_script" => {"language" => nil, "script" => "Latn"}}]}

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
    resource = create_resource(:classifications =>[ {'ref' => classification.uri} ])

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
    before(:all) do
      AppConfig[:use_human_readable_urls] = true
    end

    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via title" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :title => rand(100000).to_s))
          expected_slug = clean_slug(resource[:title])
          expect(resource[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))
          expect(resource[:slug]).to eq("foo_bar_baz")
        end
        it "dedupes slug" do
          resource1 = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :title => "foo"))
          resource2 = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :title => "foo"))
          expect(resource1[:slug]).to eq("foo")
          expect(resource2[:slug]).to eq("foo_1")
        end
        it "turns off autogen if slug is blank" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true))
          resource.update(:slug => "")
          expect(resource[:is_slug_auto]).to eq(0)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
          AppConfig[:generate_resource_slugs_with_eadid] = false
        end
        it "autogenerates a slug via identifier" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true))
          expected_slug = format_identifier_array(resource[:identifier])
          expect(resource[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :id_0 => "Foo Bar Baz&&&&", :id_1 => "", :id_2 => "", :id_3 => ""))
          expect(resource[:slug]).to eq("foo_bar_baz")
        end
        it "dedupes slug" do
          resource1 = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :id_0 => "foo", :id_1 => "", :id_2 => "", :id_3 => ""))
          resource2 = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :id_0 => "foo#", :id_1 => "", :id_2 => "", :id_3 => ""))
          expect(resource1[:slug]).to eq("foo")
          expect(resource2[:slug]).to eq("foo_1")
        end
      end
      describe "by eadid" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
          AppConfig[:generate_resource_slugs_with_eadid] = true
        end
        it "autogenerates a slug via eadid when configured to generate by eadid" do
          resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => true, :ead_id => rand(100000).to_s))
          expected_slug = clean_slug(resource[:ead_id])
          expect(resource[:slug]).to eq(expected_slug)
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => false, :slug => "foo"))
        resource.update(:title => rand(100000000))
        expect(resource[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => false, :slug => "foo"))
        resource.update(:identifier => rand(100000000))
        expect(resource[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        resource = Resource.create_from_json(build(:json_resource, :is_slug_auto => false))
        resource.update(:slug => "Foo Bar Baz ###")
        expect(resource[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        resource1 = Resource.create_from_json(build(:json_resource, :is_slug_auto => false, :slug => "foo"))
        resource2 = Resource.create_from_json(build(:json_resource, :is_slug_auto => false))

        resource2.update(:slug => "foo")

        expect(resource1[:slug]).to eq("foo")
        expect(resource2[:slug]).to eq("foo_1")
      end
    end
  end

end
