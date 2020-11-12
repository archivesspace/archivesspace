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

    expect(record).not_to be_nil
    expect(record['names'][0]['primary_name']).to eq("Feynman, Richard Phillips, 1918-1988.")
  end
end
