require 'nokogiri'
require 'spec_helper'
require_relative '../../migrations/serializers/ead.rb'


describe 'ASpaceExport' do

  it "can export a resource record as EAD" do
    r = create(:json_resource)
    
    5.times { create(:json_archival_object, :resource => {'ref' => r.uri}) }
    
    
    obj = JSONModel(:resource).find(r.id, "resolve[]" => ['repository', 'linked_agents', 'subjects', 'tree'])
    
    ead = ASpaceExport::model(:ead).from_resource(obj)
    
    serializer = ASpaceExport::serializer :ead

    xml = serializer.serialize(ead)
    doc = Nokogiri::XML(xml)


    doc.xpath('//xmlns:c', doc.root.namespaces).length.should eq (5)

  end
  
  it "can map note sub records to the appropriate EAD fields" do
    
    # cut and pasted from: http://www.loc.gov/ead/tglib/elements/archdesc.html
    exportable_note_types = %w(accessrestrict accruals acqinfo altformavail appraisal arrangement bibliography bioghist controlaccess custodhist dao daogrp descgrp did dsc fileplan index note odd originalsloc otherfindaid phystech prefercite processinfo relatedmaterial runner scopecontent separatedmaterial userestrict)

    10.times {
      note = build(:json_note_multipart)
      resource = create(:json_resource, :notes => [note])
    
      obj = JSONModel(:resource).find(resource.id, "resolve[]" => ['repository', 'linked_agents', 'subjects', 'tree'])
    
      ead = ASpaceExport::model(:ead).from_resource(obj)
    
      serializer = ASpaceExport::serializer :ead

      xml = serializer.serialize(ead)
      doc = Nokogiri::XML(xml)
    
      if exportable_note_types.include?(note.type)
        doc.xpath("//xmlns:#{note.type}", doc.root.namespaces).length.should eq (1)
      else
        doc.xpath("//xmlns:#{note.type}", doc.root.namespaces).length.should eq (0)
      end
    }
  end
    
  
  it "can export a digital object record as MODS" do
    
    extents = []
    5.times { extents << build(:json_extent) }
    
    d = create(:json_digital_object, :extents => extents)
    
    obj = JSONModel(:digital_object).find(d.id, "resolve[]" => ['repository', 'linked_agents', 'subjects', 'tree'])
    
    serializer = ASpaceExport::serializer :mods
    mods_data = ASpaceExport::model(:mods).from_digital_object(obj)
    
    xml = serializer.serialize(mods_data)
    doc = Nokogiri::XML(xml)
    
    doc.xpath('//xmlns:title', doc.root.namespaces).first.text.should eq(d.title)
    doc.xpath('//xmlns:extent', doc.root.namespaces).length.should eq (5)
  end  
  
  it "can export a digital object record as METS" do

    file_versions = []
    3.times { file_versions << build(:json_file_version)}
        
    d = create(:json_digital_object, :file_versions => file_versions)
    
    c1 = create(:json_digital_object_component, :file_versions => file_versions, :digital_object => {'ref' => d.uri})
    c2 = create(:json_digital_object_component, :file_versions => file_versions, :digital_object => {'ref' => d.uri}, :parent => {'ref' => c1.uri})
    
    obj = JSONModel(:digital_object).find(d.id, "resolve[]" => ['repository', 'linked_agents', 'subjects', 'tree'])
    
    serializer = ASpaceExport::serializer :mets
    mets = ASpaceExport::model(:mets).from_digital_object(obj)
    
    xml = serializer.serialize(mets)
    doc = Nokogiri::XML(xml)
    
    doc.xpath('//xmlns:agent/@ROLE', doc.root.namespaces).first.text.should eq('CREATOR')
    doc.xpath('//xmlns:file', doc.root.namespaces).length.should eq (9)
  end
  
  it "can export a Resource record as MARC21" do
    
    title = generate(:generic_title)
    
    r = create(:json_resource, :title => title)
    
    obj = JSONModel(:resource).find(r.id, "resolve[]" => ['repository', 'linked_agents', 'subjects'])
    
    serializer = ASpaceExport::serializer :marc21
    marc = ASpaceExport::model(:marc21).from_resource(obj)
    
    xml = serializer.serialize(marc)
    doc = Nokogiri::XML(xml)
    
    doc.xpath("//xmlns:datafield[@tag='852']/xmlns:subfield[@code='b']", doc.root.namespaces).first.text.should eq(title)
  end 
   
end


