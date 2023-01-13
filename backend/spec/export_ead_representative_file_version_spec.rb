require 'nokogiri'
require 'spec_helper'
require_relative 'export_spec_helper'

# See https://archivesspace.atlassian.net/browse/ANW-1209
describe "Representative File Version EAD Export Rules" do

  let(:digital_object_for_resource) {
    create(:json_digital_object,
           title: "dig_obj_for_resource",
           publish: true,
           file_versions: [
             build(:json_file_version,
                   is_representative: true,
                   use_statement: "image-service")
           ]
          )
  }

  let(:digital_object_for_archival_object) {
    create(:json_digital_object,
           title: "dig_obj_for_archival_object",
           publish: true,
           file_versions: [
             build(:json_file_version,
                   is_representative: true,
                   use_statement: "image-service")
           ]
          )
  }


  let(:resource) {
    resource = create(:json_resource,
                      instances: [
                        build(:json_instance_digital,
                              instance_type: 'digital_object',
                              is_representative: true,
                              digital_object: {
                                ref: digital_object_for_resource.uri
                              })
                      ]
                     )

    create(:json_archival_object,
           resource: {ref: resource.uri},
           instances: [
             build(:json_instance_digital,
                   instance_type: 'digital_object',
                   is_representative: true,
                   digital_object: {
                     ref: digital_object_for_archival_object.uri
                   })
           ]
          )
    resource
  }

  let(:ead) {
    get_ead(resource)
  }

  let(:ead3) {
    get_ead(resource, ead3: true)
  }

  # REQ 9.1 from ANW-1209 linked doc
  # If a Digital Object record with a single file version is linked as the “Representative” Digital Object instance in a Resource
  # or Archival Object record, then the EAD 2002 export for that record shall include a \"representative\" value in the <dao> element's
  # @role attribute.
  it "adds 'representative' to the @role attribute of the <dao> tag" do
    expect(ead.at_xpath("//xmlns:dao[@xlink:title='dig_obj_for_resource']")).to have_attribute("xlink:role", "image-service representative")
    expect(ead.at_xpath("//xmlns:dao[@xlink:title='dig_obj_for_archival_object']")).to have_attribute("xlink:role", "image-service representative")
  end

  # REQ 9.2 from ANW-1209 linked doc
  # If a Digital Object record with multiple file versions is linked as the \"Representative\" Digital Object instance in a Resource
  # or Archival Object record, then the EAD 2002 export for that record shall include a \"representative\" value in the <daogrp> element's
  # @role attribute.
  it "adds 'representative' to the @role attribute of the <daogrp> tag" do
    digital_object_for_resource.file_versions.push(build(:json_file_version))
    digital_object_for_resource.save
    digital_object_for_archival_object.file_versions.push(build(:json_file_version))
    digital_object_for_archival_object.save

    expect(ead.at_xpath("//xmlns:daogrp[@xlink:title='dig_obj_for_resource']")).to have_attribute("xlink:role", "representative")
    expect(ead.at_xpath("//xmlns:daogrp[@xlink:title='dig_obj_for_archival_object']")).to have_attribute("xlink:role", "representative")
  end

  # REQ 10.1 from ANW-1209 linked doc
  # If a Digital Object record with a single published File Version is linked as the “Representative” Digital Object instance in a Resource
  # or Archival Object record, then the EAD3 export for that record shall include a "representative" value in the <dao> element's @linkrole attribute.
  it "adds 'representative' to the @linkerole attribute of the <dao> tag" do
    expect(ead3.at_xpath("//xmlns:dao[@linktitle='dig_obj_for_resource']")).to have_attribute("linkrole", "image-service representative")
    expect(ead3.at_xpath("//xmlns:dao[@linktitle='dig_obj_for_archival_object']")).to have_attribute("linkrole", "image-service representative")
  end

  # REQ 10.1 from ANW-1209 linked doc
  # If a Digital Object record with multiple published File Versions is linked as the "Representative" Digital Object instance in a Resource or
  # Archival Object record, then the EAD3 export for that record shall include a "representative" value in the <daoset> element's @localtype attribute.
  # File versions marked in the Digital Object record as "Representative"  shall also include a "representative" value in the <dao> element's @linkrole
  # attribute.
  it "adds 'representative' to the @linkrole attribute of the <daoset> tag" do
    digital_object_for_resource.file_versions.push(build(:json_file_version))
    digital_object_for_resource.save
    digital_object_for_archival_object.file_versions.push(build(:json_file_version))
    digital_object_for_archival_object.save

    expect(ead3.at_xpath("//xmlns:daoset")).to have_attribute("linkrole", "representative")
    expect(ead3.at_xpath("//xmlns:dsc//xmlns:daoset")).to have_attribute("linkrole", "representative")
  end
end
