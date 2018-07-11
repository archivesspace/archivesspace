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
    @accessions.count.should eq(10)
  end

  it "created a  Agent record if one is in the row" do
    @agents.count.should eq(5)
  end
  
  it "created a Subject record if one is in the row" do
    @subjects.count.should eq(8)
  end
  
  it "created a Date record if one is in the row" do
    @dates.count.should eq(2)
  end

  it "sets the publish status correctly" do
    @accessions[0]['publish'].should eq(true)
    @accessions[1]['publish'].should eq(nil)
    @accessions[2]['publish'].should eq(true)
    @accessions[3]['publish'].should eq(nil)
  end


end

