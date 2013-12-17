require 'spec_helper'
require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def convert_test_file
    converter = DigitalObjectConverter.new(File.expand_path("../app/migrations/examples/digital_object/test_digital_object.csv",
                                                            File.dirname(__FILE__)))
    converter.run
    JSON(IO.read(converter.get_output_path))
  end


  it "did something" do
    record = convert_test_file.first

    record['jsonmodel_type'].should eq('digital_object')
    record['level'].should eq('image')
    record['title'].should eq('a new digital object')
  end
end

