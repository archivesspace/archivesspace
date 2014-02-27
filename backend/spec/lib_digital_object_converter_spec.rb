# encoding: UTF-8
require 'spec_helper'
require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def convert_test_file(input_file = "../app/exporters/examples/digital_object/test_digital_object.csv" )
    test_file = File.expand_path( input_file, File.dirname(__FILE__))
    converter = DigitalObjectConverter.instance_for('digital_object_csv', test_file)
    converter.run
    JSON(IO.read(converter.get_output_path))
  end
  

  before(:all) do
    @records = convert_test_file
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
  
  it "does something even if its a kooky utf-8 file with a BOM" do
    @records = convert_test_file('../app/exporters/examples/digital_object/test_digital_object_utf8_bom.csv')
    @digital_objects = @records.select {|r| r['jsonmodel_type'] == 'digital_object' }

    @digital_objects[0].should_not be(nil)

    @digital_objects[0]['jsonmodel_type'].should eq('digital_object')
    @digital_objects[0]['title'].should eq('DO test ¥j¥ü¥Ó/anne')

  end
end

