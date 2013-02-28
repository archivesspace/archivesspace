require 'nokogiri'
require 'spec_helper'
require_relative '../../migrations/serializers/ead.rb'


describe 'ASpaceExport' do

  it "can export a resource record as EAD" do
    resource = create(:json_resource)
    serializer = ASpaceExport::serializer :ead

    xml = serializer.serialize(Resource[resource.id])
    doc = Nokogiri::XML(xml)

    extent = resource['extents'].first

    doc.xpath('//unittitle').first.text.should eq(resource.title)
    doc.xpath('//physdesc/extent').first.text.should eq("#{extent['number']} of #{extent['extent_type']}")
  end
  
  it "can export a digital object record as MODS" do
    
    extents = []
    5.times { extents << build(:json_extent) }
    
    digital_object = create(:json_digital_object, :extents => extents)
    
    serializer = ASpaceExport::serializer :mods
    mods_data = ASpaceExport::model(:mods).from_digital_object(DigitalObject.get_or_die(digital_object.id))
    
    xml = serializer.serialize(mods_data)
    doc = Nokogiri::XML(xml)
    
    doc.xpath('//xmlns:title', doc.root.namespaces).first.text.should eq(digital_object.title)
    doc.xpath('//xmlns:extent', doc.root.namespaces).length.should eq (5)
  end  
  
  it "can export a digital object record as METS" do
        
    digital_object = create(:json_digital_object)
    
    serializer = ASpaceExport::serializer :mets
    mets = ASpaceExport::model(:mets).from_digital_object(DigitalObject.get_or_die(digital_object.id))
    
    xml = serializer.serialize(mets)
    doc = Nokogiri::XML(xml)
    
    doc.xpath('//xmlns:agent/@ROLE', doc.root.namespaces).first.text.should eq('CREATOR')
  end
  
  it "can export a Resource record as MARC21" do
    
    title = generate(:generic_title)
    
    resource = create(:json_resource, :title => title)
    
    serializer = ASpaceExport::serializer :marc21
    marc = ASpaceExport::model(:marc21).from_resource(Resource.get_or_die(resource.id))
    
    xml = serializer.serialize(marc)
    doc = Nokogiri::XML(xml)
    
    doc.xpath("//xmlns:datafield[@tag='852']/xmlns:subfield[@code='b']", doc.root.namespaces).first.text.should eq(title)
  end 
   
end


