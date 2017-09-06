require 'spec_helper'
require 'converter_spec_helper'

require_relative '../app/converters/assessment_converter.rb'

describe 'Assessment list report' do

  let(:resource) { create_resource }
  let(:accession) { create_accession }

  let(:surveyor) { JSONModel(:user).find(create_user("surveyor_user", "Surveyor User")) }
  let(:reviewer) { JSONModel(:user).find(create_user("reviewer_user", "Reviewer User")) }

  def my_converter
    AssessmentConverter
  end

  let!(:assessments) do
    assessments = []
    assessments << build(:json_assessment, {
                           'records' => [{'ref' => resource.uri}],
                           'surveyed_by' => [surveyor.agent_record],
                           'reviewer' => [reviewer.agent_record],
                         })

    assessments << build(:json_assessment, {
                           'records' => [{'ref' => resource.uri},
                                         {'ref' => accession.uri}],
                           'surveyed_by' => [surveyor.agent_record],
                           'reviewer' => [reviewer.agent_record],
                         })

    assessments.each do |a|
      Assessment.create_from_json(a)
    end

    assessments
  end

  it "produces a CSV file that can be round-tripped with the importer" do
    csv = DB.open do |db|
      AssessmentListReport.new({:repo_id => $repo_id}, {}, db).to_csv
    end

    # two header rows; two records
    csv.split("\n").length.should eq(4)

    Tempfile.open('assessment_csv') do |tempfile|
      tempfile.write(csv)
      tempfile.flush

      records = convert(tempfile.path)

      records.length.should eq(2)

      records.map {|assessment| assessment['survey_begin']}.sort
        .should eq(assessments.map {|assessment| assessment['survey_begin']}.sort)

      records.map {|assessment| assessment['records']}.sort
        .should eq(assessments.map {|assessment| assessment['records']}.sort)
    end
  end

  it "produces a report in JSON format" do
    json_str = DB.open do |db|
      AssessmentListReport.new({:repo_id => $repo_id}, {}, db).to_json
    end

    json = ASUtils.json_parse(json_str)

    json.map {|assessment| assessment['basic']['survey_begin']}.sort
      .should eq(assessments.map {|assessment| assessment['survey_begin']}.sort)
  end

end
