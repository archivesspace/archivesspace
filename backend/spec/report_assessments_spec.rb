require 'spec_helper'
require 'converter_spec_helper'
require 'assessment_spec_helper'

require_relative '../app/converters/assessment_converter.rb'

describe 'Assessment reports' do

  before(:all) do
    AssessmentSpecHelper.setup_global_attributes
  end

  let(:resource) { create_resource }
  let(:accession) { create_accession }

  let(:surveyor) { JSONModel(:user).find(create_user("surveyor_user", "Surveyor User")) }
  let(:reviewer) { JSONModel(:user).find(create_user("reviewer_user", "Reviewer User")) }

  let!(:attribute_definitions) do
    AssessmentAttributeDefinitions.get($repo_id)
  end

  def definition_id_for_attribute_type(type)
    attribute_definitions.definitions.find {|d| d[:type] == type}.fetch(:id)
  end

  let!(:assessments) do
    assessments = []

    base_record = {
      'surveyed_by' => [surveyor.agent_record],
      'surveyed_extent' => 'surveyed extent',
      'reviewer' => [reviewer.agent_record],
      'inactive' => false,
      'formats' => [
        {
          "definition_id" => definition_id_for_attribute_type('format'),
          "value" => "true",
        }
      ],
      'conservation_issues' => [
        {
          "definition_id" => definition_id_for_attribute_type('conservation_issue'),
          "value" => "true",
        }
      ]
    }

    assessments << build(:json_assessment,
                         base_record.merge({
                                             'records' => [{'ref' => resource.uri}],
                                             'ratings' => [
                                               {
                                                 "definition_id" => definition_id_for_attribute_type('rating'),
                                                 "value" => "5",
                                               }
                                             ],
                                           }))

    assessments << build(:json_assessment,
                         base_record.merge({
                                             'records' => [{'ref' => resource.uri},
                                                           {'ref' => accession.uri}],
                                             'ratings' => [
                                               {
                                                 "definition_id" => definition_id_for_attribute_type('rating'),
                                                 "value" => "3",
                                               }
                                             ],
                                           }))

    assessments << build(:json_assessment,
                         base_record.merge({
                                             'inactive' => true,
                                             'records' => [{'ref' => accession.uri}],
                                             'ratings' => [
                                               {
                                                 "definition_id" => definition_id_for_attribute_type('rating'),
                                                 "value" => "4",
                                               }
                                             ],
                                           }))

    assessments.each do |a|
      Assessment.create_from_json(a)
    end

    assessments
  end

  def active_assessments
    assessments.reject {|a| a['inactive']}
  end

  describe 'Assessment list report' do

    def my_converter
      AssessmentConverter
    end

    it "excludes inactive assessments" do
      DB.open do |db|
        AssessmentListReport.new({:repo_id => $repo_id}, {}, db).total_count.should eq(2)
      end
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
          .should eq(active_assessments.map {|assessment| assessment['survey_begin']}.sort)

        records.map {|assessment| assessment['records']}.sort
          .should eq(active_assessments.map {|assessment| assessment['records']}.sort)
      end
    end

    it "produces a report in JSON format" do
      json_str = DB.open do |db|
        AssessmentListReport.new({:repo_id => $repo_id}, {}, db).to_json
      end

      json = ASUtils.json_parse(json_str)

      json.map {|assessment| assessment['basic']['survey_begin']}.sort
        .should eq(active_assessments.map {|assessment| assessment['survey_begin']}.sort)
    end
  end

  describe 'Assessment rating report' do

    let (:params) do
      definition_id = definition_id_for_attribute_type('rating')

      {:repo_id => $repo_id,
       'rating' => definition_id,
       'value_5' => 'on'}
    end

    it "excludes inactive assessments" do
      DB.open do |db|
        # Matches '5' but not '4', since that record is inactive.
        AssessmentRatingReport.new(params.merge('value_4' => 'on'), {}, db).count.should eq(1)
      end
    end

    it "produces a CSV file with matching ratings" do
      csv = DB.open do |db|
        AssessmentRatingReport.new(params, {}, db).to_csv
      end

      # one header row; one record
      csv.split("\n").length.should eq(2)
    end

    it "produces a report in JSON format" do
      json_str = DB.open do |db|
        AssessmentRatingReport.new(params, {}, db).to_json
      end

      json = ASUtils.json_parse(json_str)

      json.length.should eq(1)

      json[0]['Extent'].should eq('surveyed extent')
    end
  end
end
