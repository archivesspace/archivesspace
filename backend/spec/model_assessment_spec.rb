require 'spec_helper'

describe 'Assessment model' do

  let(:resource) { create_resource }
  let(:surveyor) { create(:json_agent_person) }

  it "can create an assessment" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => {'ref' => surveyor.uri},
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.should_not be_nil
    json.records.should_not be_empty
    json.records.first['ref'].should eq(resource.uri)

    json.surveyed_by.should_not be_nil
    json.surveyed_by['ref'].should eq(surveyor.uri)
  end


  it "can create an assessment with material" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => {'ref' => surveyor.uri},
      'materials' => [build(:json_assessment_material, 'material_note' => 'my stuff')]
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.materials.should_not be_empty
    json.materials.first['material_note'].should eq('my stuff')
  end


  it "can create an assessment with a conservation issue" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
      'records' => [{'ref' => resource.uri}],
      'surveyed_by' => {'ref' => surveyor.uri},
      'conservation_issues' => [build(:json_assessment_conservation_issue, 'issue_note' => 'all gross')]
    }))

    json = Assessment.to_jsonmodel(assessment.id)
    json.conservation_issues.should_not be_empty
    json.conservation_issues.first['issue_note'].should eq('all gross')
  end

end
