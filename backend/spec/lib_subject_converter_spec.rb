require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/subject_converter'

describe 'Subject converter' do

  def my_converter
    SubjectConverter
  end


  before(:all) do
    test_file = File.expand_path("../../backend/spec/examples/aspace_subject_import_template.csv",
                                 File.dirname(__FILE__))

    @records = convert(test_file)
    @subjects = @records.select {|r| r['jsonmodel_type'] == 'subject' }
  end

  it "created one Subject record for each row in the CSV file, with subrecords if included" do
    expect(@subjects.count).to eq(2)
    expect(@subjects[0]["external_documents"].count).to eq(1)
    expect(@subjects[0]["metadata_rights_declarations"].count).to eq(1)
  end
end
