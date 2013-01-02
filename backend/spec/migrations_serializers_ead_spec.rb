require 'nokogiri'
require 'spec_helper'
require_relative '../../migrations/serializers/ead.rb'


describe 'EAD serializer' do

  it "can serialize a resource record" do
    resource = create(:json_resource)
    serializer = ASpaceExport::serializer :ead

    xml = serializer.serialize(Resource[resource.id])
    doc = Nokogiri::XML(xml)

    extent = resource['extents'].first

    doc.xpath('//unittitle').first.text.should eq(resource.title)
    doc.xpath('//physdesc/extent').first.text.should eq("#{extent['number']} of #{extent['extent_type']}")
  end

end
