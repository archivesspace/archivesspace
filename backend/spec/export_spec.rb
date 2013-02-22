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
  
  it "can export a digital object records as MODS" do
    
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
end


