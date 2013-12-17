require 'spec_helper'
require_relative '../app/converters/eac_converter'

describe 'EAC converter' do

  def convert_test_file
    test_file = File.expand_path("../app/migrations/examples/eac/feynman-richard-phillips-1918-1988-cr.xml",
                                 File.dirname(__FILE__))
    converter = EACConverter.instance_for('eac_xml', test_file)
    converter.run
    JSON(IO.read(converter.get_output_path))
  end


  it "did something" do
    record = convert_test_file.first

    record.should_not be(nil)
    record['names'][0]['primary_name'].should eq("Feynman, Richard Phillips, 1918-1988.")
  end
end

