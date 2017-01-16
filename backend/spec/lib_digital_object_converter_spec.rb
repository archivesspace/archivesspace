# encoding: UTF-8
require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def my_converter
    DigitalObjectConverter
  end


  before(:all) do
    test_file = File.expand_path("../app/exporters/examples/digital_object/aspace_digital_object_import_template.csv",
                                 File.dirname(__FILE__))
    @records = convert(test_file)
    @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }
  end


  it "did something" do
    @digital_objects[0].should_not be(nil)

    @digital_objects[0]['jsonmodel_type'].should eq('digital_object')
    @digital_objects[0]['level'].should eq('image')
    @digital_objects[0]['title'].should eq('a new digital object')
    @digital_objects[0]['publish'].should eq(true)
  end



  it "maps digital_object_file version information to the object" do
    @digital_objects[0]['file_versions'].length.should eq(1)
    {"jsonmodel_type"=>"file_version", "uri"=>nil, "file_uri"=>"http://aspace.me", "publish"=>true, "use_statement"=>"It's all good", "xlink_actuate_attribute"=>"onRequest", "xlink_show_attribute"=>"embed", "file_format_name"=>"jpeg", "file_format_version"=>"1", "file_size_bytes"=>100, "checksum"=>"xxxxxxx", "checksum_method"=>"md5"}.each do |k, v|
      @digital_objects[0]["file_versions"][0][k].should eq(v)
    end
  end


  describe "utf-8 encoding" do
    let(:test_file_bom) {
      File.expand_path('../app/exporters/examples/digital_object/test_digital_object_utf8_bom.csv',
                       File.dirname(__FILE__))
    }

    it "does something even if its a kooky utf-8 file with a BOM" do
      @records = convert(test_file_bom)
      @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }

      @digital_objects[0].should_not be(nil)

      @digital_objects[0]['jsonmodel_type'].should eq('digital_object')
      @digital_objects[0]['title'].should eq('DO test ¥j¥ü¥Ó/anne')
    end
  end
end
