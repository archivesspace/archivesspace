require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/eac_converter'

describe 'EAC converter' do

  let(:my_converter) {
    EACConverter
  }

  let(:test_file) {
    File.expand_path("../app/exporters/examples/eac/feynman-richard-phillips-1918-1988-cr.xml",
                     File.dirname(__FILE__))
  }


  it "did something" do
    record = convert(test_file).first

    record.should_not be(nil)
    record['names'][0]['primary_name'].should eq("Feynman, Richard Phillips, 1918-1988.")
  end
end

