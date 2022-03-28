require 'spec_helper'

# see https://archivesspace.atlassian.net/browse/ANW-1522
describe 'Representative File Version mixin' do

  describe "Resource, Accession, and Archival Object representative file version" do
    it "If the record has an is_representative instance, and that instance refers to a digital object which has a representative_file_version (or one could be calculated),  use / copy the representative_file_version object on the linked digital object." do

      do1 = create(:json_digital_object, {
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

      do2 = create(:json_digital_object, {
                     :publish => true,
                     :file_versions => [build(:json_file_version, {
                                                :publish => true,
                                                :file_uri => 'http://foo.com/bar3',
                                                :use_statement => 'image-service'
                                              }),
                                        build(:json_file_version, {
                                                :publish => true,
                                                :is_representative => true,
                                                :file_uri => 'http://foo.com/bar4',
                                                :use_statement => 'image-service'
                                              })
                                       ]})


      resource = create_resource({
                                   :instances => [build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do1.uri}
                                                        }),
                                                  build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do2.uri},
                                                          :is_representative => true
                                                        })
                                                 ]
                                 })

      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq('http://foo.com/bar4')

      accession = create_accession({
                                   :instances => [build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do1.uri}
                                                        }),
                                                  build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do2.uri},
                                                          :is_representative => true
                                                        })
                                                 ]
                                   })

      accession = Accession.to_jsonmodel(accession.id)
      expect(accession.representative_file_version['file_uri']).to eq('http://foo.com/bar4')

      archival_object = create_archival_object({
                                   :instances => [build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do1.uri}
                                                        }),
                                                  build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do2.uri},
                                                          :is_representative => true
                                                        })
                                                 ]
                                 })

      archival_object = ArchivalObject.to_jsonmodel(archival_object.id)
      expect(archival_object.representative_file_version['file_uri']).to eq('http://foo.com/bar4')
    end

    it "if the record has an is_representative instance, and that instance refers to a digital object which does not have a representative_file_version , iterate through any digital object component records within the linked digital object's tree until one is found with a representative_file_version." do

      do1 = create(:json_digital_object, {
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

      # this is the representative instance, but its file versions are all unpublished and hence cannot be selected
      do2 = create(:json_digital_object, {
                     :publish => true,
                     :file_versions => [build(:json_file_version, {
                                                :publish => false,
                                                :file_uri => 'http://foo.com/bar3',
                                                :use_statement => 'image-service'
                                              }),
                                        build(:json_file_version, {
                                                :publish => false,
                                                :file_uri => 'http://foo.com/bar4',
                                                :use_statement => 'image-service'
                                              })
                                       ]})
      # so we will have to look here..
      doc1 = create(:json_digital_object_component, {
                      :publish => true,
                      :digital_object => {"ref" => do2.uri},
                      :file_versions => [build(:json_file_version, {
                                                 :publish => false,
                                                 :file_uri => 'http://foo.com/bar5',
                                                 :use_statement => 'image-service'
                                               }),
                                         build(:json_file_version, {
                                                 :publish => false,
                                                 :file_uri => 'http://foo.com/bar6',
                                                 :use_statement => 'image-service'
                                               })
                                        ]})

      # ..and here
      doc2 = create(:json_digital_object_component, {
                      :publish => true,
                      :digital_object => {"ref" => do2.uri},
                      :file_versions => [build(:json_file_version, {
                                                 :publish => true,
                                                 :file_uri => 'http://foo.com/bar7',
                                                 :use_statement => 'image-service'
                                               }),
                                         build(:json_file_version, {
                                                 :publish => true,
                                                 :is_representative => true,
                                                 :file_uri => 'http://foo.com/bar8',
                                                 :use_statement => 'image-service'
                                               })
                                        ]})


      resource = create_resource({
                                   :instances => [build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do1.uri}
                                                        }),
                                                  build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do2.uri},
                                                          :is_representative => true
                                                        })
                                                 ]
                                 })
      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq('http://foo.com/bar8')

      accession = create_accession({
                                     :instances => [build(:json_instance_digital, {
                                                            :digital_object => {'ref' => do1.uri}
                                                          }),
                                                    build(:json_instance_digital, {
                                                            :digital_object => {'ref' => do2.uri},
                                                            :is_representative => true
                                                          })
                                                   ]
                                   })

      accession = Accession.to_jsonmodel(accession.id)
      expect(accession.representative_file_version['file_uri']).to eq('http://foo.com/bar8')

      archival_object = create_archival_object({
                                   :instances => [build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do1.uri}
                                                        }),
                                                  build(:json_instance_digital, {
                                                          :digital_object => {'ref' => do2.uri},
                                                          :is_representative => true
                                                        })
                                                 ]
                                 })

      archival_object = ArchivalObject.to_jsonmodel(archival_object.id)
      expect(archival_object.representative_file_version['file_uri']).to eq('http://foo.com/bar8')

    end
  end

  describe "Resource only" do
    it "If neither of the previous steps produces a representative, iterate through each Archival Object in the tree until one is found having a representative and assume that." do
      do1 = create(:json_digital_object, {
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

      resource = create_resource

      archival_object = create_archival_object({
                                                 :resource => {"ref" => resource.uri},
                                                 :instances => [build(:json_instance_digital, {
                                                                        :digital_object => {'ref' => do1.uri},
                                                                        :is_representative => true
                                                                      })]
                                               })

      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq('http://foo.com/bar2')

    end
  end
end
