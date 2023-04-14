require 'spec_helper'

# Backend Rules Derived from documentation for https://archivesspace.atlassian.net/browse/ANW-1209
#
# This spec documents how the .representative_file_version read-only property is calculated for
# Digital Object, Archival Object, Accession and Resource records.
# There are three parts:
# 1. How the property is calcualted for a digital object / digital object component
# 2. How the property is calculated for a resource, archival object, or accession with a representative instance that
#    contains a digital object link
# 3. How the property is calculated for a resource when it does not have a representative instances with a digital object
#    link
#
# Rules for how the 'is_representative' flag can be set on file versions and instances can be found in the respective model specs.

# see https://archivesspace.atlassian.net/browse/ANW-1522
describe 'Representative File Version mixin' do

  10.times { |i|
    let(:"file_version_#{i}") {
      build(:json_file_version, {
              :publish => true,
              :file_uri => "http://foo.com/bar#{i}",
              :use_statement => 'image-service',
              :xlink_show_attribute => "embed"
            })
    }
  }

  describe "Digital Object / Digital Object Component representative file version" do

    it "has a representative_file_version read-only value of the published file_version marked 'is_representative' if there"\
        " is a file_version marked 'is_representative'" do
      file_version_2.is_representative = true
      [DigitalObject, DigitalObjectComponent].each do |klass|
        json = build(:"json_#{klass.name.underscore}", file_versions: [ file_version_1, file_version_2 ])
        obj = klass.create_from_json(json)
        json = klass.to_jsonmodel(obj)
        expect(json.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
      end
    end

    it "has a representative_file_version read-only value of the first published file_version with a use-statement marked"\
       " 'image-thumbnail' if there is no file_version marked 'is_representative'" do
      file_version_2['use_statement'] = 'image-thumbnail'
      file_version_3['use_statement'] = 'image-thumbnail'
      [DigitalObject, DigitalObjectComponent].each do |klass|
        json = build(:"json_#{klass.name.underscore}", file_versions: [ file_version_1, file_version_2, file_version_3 ])
        obj = klass.create_from_json(json)
        json = klass.to_jsonmodel(obj)
        expect(json.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
      end
    end

    it "has a representative_file_version read-only value of the first published file_version with a file_uri"\
       " that starts with 'http' and a xlink_show_attribute value of 'embed' if there is no"\
       " file_version marked 'is_representative' and there is no published file_version with a"\
       " use-statement marked 'image-thumbnail'" do
      file_version_1.publish = false
      file_version_3.publish = false
      file_version_3.use_statement = 'image-thumbnail'
      file_version_2.xlink_show_attribute = 'embed'
      [DigitalObject, DigitalObjectComponent].each do |klass|
        json = build(:"json_#{klass.name.underscore}", file_versions: [ file_version_1, file_version_2, file_version_3 ])
        obj = klass.create_from_json(json)
        json = klass.to_jsonmodel(obj)
        expect(json.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
      end
    end

    # https://archivesspace.atlassian.net/browse/ANW-1721
    it "has a read-only 'link_uri' for the following published sibling file_version of the representative file" do
      file_version_2.is_representative = true
      [DigitalObject, DigitalObjectComponent].each do |klass|
        json = build(:"json_#{klass.name.underscore}", file_versions: [ file_version_1, file_version_2, file_version_3 ])
        obj = klass.create_from_json(json)
        json = klass.to_jsonmodel(obj)
        expect(json.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
        expect(json.representative_file_version['link_uri']).to eq(file_version_3.file_uri)
      end
    end

    it "has no read-only 'link_uri' if the following file_version of the representative file is unpublished" do
      file_version_2.is_representative = true
      file_version_3.publish = false
      [DigitalObject, DigitalObjectComponent].each do |klass|
        json = build(:"json_#{klass.name.underscore}", file_versions: [ file_version_1, file_version_2, file_version_3, file_version_4 ])
        obj = klass.create_from_json(json)
        json = klass.to_jsonmodel(obj)
        expect(json.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
        expect(json.representative_file_version['link_uri']).to be_nil
      end
    end
  end

  describe "Resource, Accession, and Archival Object representative file version" do

    it "if the record has an is_representative instance, and that instance refers to a digital object"\
        " which has a representative_file_version,  use / copy the representative_file_version"\
        " object on the linked digital object." do

      do1 = create(:json_digital_object, publish: true, file_versions: [file_version_1])
      file_version_2.publish = false
      file_version_3.is_representative = true
      do2 = create(:json_digital_object, publish: true, file_versions: [file_version_2, file_version_3])
      create_args = { instances: [
                        build(:json_instance_digital, {
                                digital_object: { ref: do1.uri }
                              }),
                        build(:json_instance_digital, {
                                digital_object: { ref: do2.uri },
                                is_representative: true
                              })] }

      [Resource, Accession, ArchivalObject].each do |klass|
        obj = send("create_#{klass.name.underscore}", instances: [
                     build(:json_instance_digital, {
                             digital_object: { ref: do1.uri }
                           }),
                     build(:json_instance_digital, {
                             digital_object: { ref: do2.uri },
                             is_representative: true
                           })])

        json = klass.to_jsonmodel(obj.id)
        expect(json.representative_file_version['file_uri']).to eq(file_version_3.file_uri)
        expect(json.representative_file_version['derived_from']).to eq(do2.uri)
      end
    end
  end

  describe "Digital Object only" do
    it "if rfv cannot be calculated for a DigitalObject iterate through any DigitalObjectComponent records in the parent tree"\
        " until one is found with a representative_file_version, but only do this if the representative file version"\
         " is being invoked within the context of a Resource, Archival Object, or Accession" do

      file_version_1.publish = false
      do1 = create(:json_digital_object, { publish: true, file_versions: [file_version_1] })

      # this will be the first component, but fv not published
      file_version_2.publish = false
      do1_c1 = create(:json_digital_object_component, {
                        publish: true,
                        digital_object: { ref: do1.uri },
                        file_versions: [file_version_2]
                      })

      file_version_4.is_representative = true
      do1_c2 = create(:json_digital_object_component, {
                        publish: true,
                        digital_object: { ref: do1.uri },
                        file_versions: [ file_version_3, file_version_4]
                      })

      do1 = DigitalObject.to_jsonmodel(do1.id)
      expect(do1.representative_file_version).to be_nil

      # confirm that this is consistent for digobj-instance-havers
      [Resource, Accession, ArchivalObject].each do |klass|
        obj = send("create_#{klass.name.underscore}", instances: [
                     build(:json_instance_digital, {
                             is_representative: true,
                             digital_object: { ref: do1.uri }
                           })])

        json = klass.to_jsonmodel(obj.id)
        expect(json.representative_file_version['file_uri']).to eq(file_version_4.file_uri)
      end
    end

    it "selects file versions in order from top to bottom through the expanded tree" do
      file_version_1.use_statement = 'image-thumbnail'
      file_version_2.use_statement = 'image-thumbnail'
      file_version_3.publish = false
      file_version_4.publish = false
      file_version_5.publish = false

      do1 = create(:json_digital_object, { publish: true, file_versions: [] })

      do1_c1 = create(:json_digital_object_component, {
                        publish: true,
                        digital_object: { ref: do1.uri },
                        position: 1000,
                        file_versions: []
                      })

      do1_c2 = create(:json_digital_object_component, {
                        publish: true,
                        digital_object: { ref: do1.uri },
                        position: 2000,
                        file_versions: [ file_version_2 ]
                      })

      do1_c1_c1 = create(:json_digital_object_component, {
                           publish: true,
                           digital_object: { ref: do1.uri },
                           parent: { ref: do1_c1.uri },
                           position: 1000,
                           file_versions: []
                         })

      do1_c1_c2 = create(:json_digital_object_component, {
                           publish: true,
                           digital_object: { ref: do1.uri },
                           parent: { ref: do1_c1.uri },
                           position: 2000,
                           file_versions: [ file_version_5 ]
                         })

      do1_c1_c3 = create(:json_digital_object_component, {
                           publish: true,
                           digital_object: { ref: do1.uri },
                           parent: { ref: do1_c1.uri },
                           position: 3000,
                           file_versions: [ file_version_3, file_version_1, file_version_4 ]
                         })

      accession = create(:json_accession, {
                           instances: [
                             build(:json_instance_digital, {
                                     is_representative: true,
                                     digital_object: { ref: do1.uri }
                                   })]
                         })

      expect(accession.representative_file_version['file_uri']).to eq(file_version_1.file_uri)
    end

    it "has no read-only 'link_uri' since this field only matters in the context of a digital object record or component" do
      do1 = create(:json_digital_object, { publish: true, file_versions: [file_version_1, file_version_2] })

      [Resource, Accession, ArchivalObject].each do |klass|
        obj = send("create_#{klass.name.underscore}", instances: [
                     build(:json_instance_digital, {
                             is_representative: true,
                             digital_object: { ref: do1.uri }
                           })])

        json = klass.to_jsonmodel(obj.id)
        expect(json.representative_file_version['file_uri']).to eq(file_version_1.file_uri)
        expect(json.representative_file_version['link_uri']).to be_nil
      end
    end
  end


  describe "Resource only" do

    it "if rfv cannot be calculated for a resource iterate through any archival object records in the parent tree"\
       " until one is found with a representative instance linking to a digital object representative_file_version." do

      resource = create_resource
      file_version_1.xlink_show_attribute = 'embed'
      file_version_2.is_representative = true
      file_version_3.use_statement = 'image-thumbnail'
      do1 = create(:json_digital_object, publish: true, file_versions: [file_version_1])
      do2 = create(:json_digital_object, publish: true, file_versions: [file_version_2])
      do3 = create(:json_digital_object, publish: true, file_versions: [])
      do3_c1 = create(:json_digital_object_component, {
                        publish: true,
                        digital_object: { ref: do3.uri },
                        file_versions: [ file_version_3 ]
                      })

      ao1 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 0,
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do1.uri },
                                                         is_representative: true
                                                       })]
                                   })
      ao2 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 1,
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do2.uri },
                                                         is_representative: true
                                                       })]
                                   })
      ao3 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 2,
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do3.uri },
                                                         is_representative: true
                                                       }) ]
                                   })

      ao1_mtime_1 = ao1.system_mtime.utc.iso8601

      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_1 = resource.system_mtime
      expect(resource.representative_file_version['file_uri']).to eq(file_version_1.file_uri)

      ArchivesSpaceService.wait(:long)
      do1 = DigitalObject.to_jsonmodel(do1.id)
      do1.file_versions[0]['publish'] = false
      do1.save

      # do1 is still the representative instance, but it no longer has a valid
      # representative file version, so the resource won't either
      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_2 = resource.system_mtime
      expect(resource.representative_file_version).to be_nil
      expect(resource_mtime_2).to be > resource_mtime_1
      ao1 = ArchivalObject.to_jsonmodel(ao1.id)
      ao1_mtime_2 = ao1.system_mtime
      expect(ao1_mtime_2).to be > ao1_mtime_1

      ArchivesSpaceService.wait(:long)
      do1.delete

      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_3 = resource.system_mtime
      expect(resource.representative_file_version['file_uri']).to eq(file_version_2.file_uri)
      expect(resource_mtime_3).to be > resource_mtime_2

      do2.delete
      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq(file_version_3.file_uri)

      ArchivesSpaceService.wait(:long)
      do3_c1.file_versions[0]['publish'] = false
      do3_c1.save
      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_4 = resource.system_mtime
      expect(resource.representative_file_version).to be_nil
      expect(resource_mtime_4).to be > resource_mtime_3

      ArchivesSpaceService.wait(:long)
      do3_c1.file_versions[0]['publish'] = true
      do3_c1.save
      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_5 = resource.system_mtime
      expect(resource.representative_file_version['file_uri']).to eq(file_version_3.file_uri)
      expect(resource_mtime_5).to be > resource_mtime_4

      ArchivesSpaceService.wait(:long)
      do3_c1.delete
      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_6 = resource.system_mtime
      expect(resource.representative_file_version).to be_nil
      expect(resource_mtime_6).to be > resource_mtime_5
    end

    it "selects the first object in the tree with a representative do instance, "\
       " 'first' meaning first in absolute order if all tree nodes are expanded" do

      # ^ = no representative instance; * = expected to be selected for resource
      # - resource
      #   - ao 1^
      #     - ao 2^
      #     - ao 3^
      #     - ao 4*
      #   - ao 5
      #  (moves ao5 to top of tree)
      # - resource
      #   - ao 5*
      #   - ao 1^
      #     - ao 2^
      #     - ao 3^
      #     - ao 4

      resource = create_resource
      file_version_4.is_representative = true
      file_version_5.xlink_show_attribute = 'embed'
      do4 = create(:json_digital_object, publish: true, file_versions: [file_version_4])
      do5 = create(:json_digital_object, publish: true, file_versions: [file_version_5])

      ao1 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 1000,
                                     title: "ao1 #{Time.now.to_i}"
                                   })

      ao2 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 1000,
                                     parent: {ref: ao1.uri},
                                     title: "ao2 #{Time.now.to_i}"
                                   })

      ao3 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 2000,
                                     parent: {ref: ao1.uri},
                                     title: "ao3 #{Time.now.to_i}"
                                   })

      ao4 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 3000,
                                     parent: {ref: ao1.uri},
                                     title: "ao4 #{Time.now.to_i}",
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do4.uri },
                                                         is_representative: true
                                                       })]
                                   })

      ao5 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     position: 2000,
                                     title: "ao5 #{Time.now.to_i}",
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do5.uri },
                                                         is_representative: true
                                                       }) ]
                                   })

      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq(file_version_4.file_uri)

      ao5.position = 0
      ao5.save

      resource = Resource.to_jsonmodel(resource.id)
      expect(resource.representative_file_version['file_uri']).to eq(file_version_5.file_uri)
    end

    it "ignores unpublished archival objects when searching a resource tree for a representative" do

      resource = create_resource
      file_version_1.is_representative = true
      file_version_2.is_representative = true

      do1 = create(:json_digital_object, publish: true, file_versions: [file_version_1])
      do2 = create(:json_digital_object, publish: true, file_versions: [file_version_2])

      ao1 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: false,
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do1.uri },
                                                         is_representative: true
                                                       })]})

      ao2 = create_archival_object({
                                     resource: { ref: resource.uri},
                                     publish: true,
                                     instances: [build(:json_instance_digital, {
                                                         digital_object: { ref: do2.uri },
                                                         is_representative: true
                                                       })]})

      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_1 = resource.system_mtime
      expect(resource.representative_file_version['file_uri']).to eq(file_version_2.file_uri)

      ArchivesSpaceService.wait(:long)
      ao1.publish!

      resource = Resource.to_jsonmodel(resource.id)
      resource_mtime_2 = resource.system_mtime
      expect(resource.representative_file_version['file_uri']).to eq(file_version_1.file_uri)
      expect(resource_mtime_2).to be > resource_mtime_1
    end
  end
end
