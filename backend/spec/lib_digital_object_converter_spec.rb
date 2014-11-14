# encoding: UTF-8
require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do
  let(:my_converter) {
    DigitalObjectConverter
  }

  let(:test_file) {
    File.expand_path("../app/exporters/examples/digital_object/aspace_digital_object_import_template.csv",
                     File.dirname(__FILE__))
  }

  before(:all) do
    @records = convert(test_file)
    @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }
  end


  it "did something" do
    @digital_objects[0].should_not be(nil)

    @digital_objects[0]['jsonmodel_type'].should eq('digital_object')
    @digital_objects[0]['level'].should eq('image')
    @digital_objects[0]['title'].should eq('a new digital object')
  end


  it "maps digital_object_processing_started_date to collection_management.processing_started_date" do    
    @digital_objects[0]['collection_management']['processing_started_date'].should match(/\d{4}-\d{2}-\d{2}/)
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

