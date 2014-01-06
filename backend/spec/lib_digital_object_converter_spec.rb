require 'spec_helper'
require_relative '../app/converters/digital_object_converter'

describe 'Digital Object converter' do

  def convert_test_file
    test_file = File.expand_path("../app/migrations/examples/digital_object/test_digital_object.csv",
                                 File.dirname(__FILE__))
    converter = DigitalObjectConverter.instance_for('digital_object_csv', test_file)
    converter.run
    JSON(IO.read(converter.get_output_path))
  end


  it "did something" do
    record = convert_test_file.find {|rec| rec['jsonmodel_type'] == 'digital_object'}
    record.should_not be(nil)

    record['jsonmodel_type'].should eq('digital_object')
    record['level'].should eq('image')
    record['title'].should eq('a new digital object')
  end
end

