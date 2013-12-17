require 'spec_helper'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do

  def convert_test_file
    test_file = File.expand_path("../app/migrations/examples/accession/test_accession.csv",
                                 File.dirname(__FILE__))
    converter = AccessionConverter.instance_for('accession_csv', test_file)
    converter.run
    JSON(IO.read(converter.get_output_path))
  end


  it "did something" do
    record = convert_test_file.select {|rec| rec['jsonmodel_type'] == 'accession'}

    record.count.should eq(25)
  end
end

