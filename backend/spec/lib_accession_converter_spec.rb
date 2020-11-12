require 'spec_helper'
require 'converter_spec_helper'
require 'csv'
require_relative '../app/converters/accession_converter'

describe 'Accession converter' do

  def my_converter
    AccessionConverter
  end


  before(:all) do
    test_file = File.expand_path("../app/exporters/examples/accession/aspace_accession_import_template.csv",
                                 File.dirname(__FILE__))

    @records = convert(test_file)
    @accessions = @records.select {|r| r['jsonmodel_type'] == 'accession' }
    @agents = @records.select { |a| a['jsonmodel_type'].include?('agent_')  }
    @subjects = @records.select { |a| a['jsonmodel_type'] == 'subject'  }
    @dates = []
    @accessions.each { |a| @dates = @dates +  a['dates'] }
  end

  it "created one Accession record for each row in the CSV file" do
    expect(@accessions.count).to eq(10)
  end

  it "created a  Agent record if one is in the row" do
    expect(@agents.count).to eq(5)
  end

  it "created a Subject record if one is in the row" do
    expect(@subjects.count).to eq(8)
  end

  it "created a Date record if one is in the row" do
    expect(@dates.count).to eq(2)
  end

  it "sets the publish status correctly" do
    expect(@accessions[0]['publish']).to be_truthy
    expect(@accessions[1]['publish']).to be_nil
    expect(@accessions[2]['publish']).to be_truthy
    expect(@accessions[3]['publish']).to be_nil
  end


end
